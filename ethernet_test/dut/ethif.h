
#pragma once
#ifndef __ETHIF_H__
#define __ETHIF_H__

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <linux/mii.h>

class ethif {
private:
    std::string ifname;
    std::string ipaddr;
    int         sock;
    int         phyid;

    struct ifreq        ifr;
    struct ethtool_cmd  edata;

    bool        ifstate; // interface up or down?

    void
    syscommand(std::string cmd)
    {
        printf("cmd -> %s\n", cmd.c_str() );
        system(cmd.c_str());
    }

    void
    initialize(void)
    {
        sock = -1;
        phyid = 0;
        sock = socket(PF_INET, SOCK_DGRAM, 0);
    }

    int
    ethtool_gset(void)
    {
        int rc;
        initifr();    
        memset(&edata, 0, sizeof(edata));
        ifr.ifr_data = (__caddr_t)&edata;
        edata.cmd = ETHTOOL_GSET;

        rc = ioctl(sock, SIOCETHTOOL, &ifr);

        if (rc < 0) {
            printf("ioctl error in ETHTOOL_GSET\n");
            exit(1);
        }

        switch (edata.speed) {
            case SPEED_10: printf("10Mbps\n"); break;
            case SPEED_100: printf("100Mbps\n"); break;
            case SPEED_1000: printf("1000Mbps\n"); break;
            default: printf("speed default %d\n", edata.speed); break;
        }
    }

    void
    initifr(void)
    {
        memset(&ifr, 0, sizeof(ifr));
        strcpy(ifr.ifr_name, ifname.c_str()); 
    }
public:

    ethif(char *ifn) : ipaddr("")
    {
        ifname = ifn;
        initialize();
    }

    ethif(char *ifn, char *ipaddr) 
    {
        ifname = ifn;
        this->ipaddr = ipaddr;
        initialize();
    }

    ~ethif()
    {
        close(sock);
    }

    void
    setipaddr(char *ipaddr)
    {
        this->ipaddr = ipaddr;
    }

    void
    ethdown()
    {
        std::string cmd = "ifconfig " + ifname + " down";
        syscommand(cmd);
    }

    int
    getlinkstatus(int *plink)
    {
        int s;
        int rc;
        struct ethtool_value edata;
        int ret = 1; // assume success
        initifr();
        *plink = -1;

        memset(&edata, 0, sizeof(edata));

        edata.cmd = ETHTOOL_GLINK;
        ifr.ifr_data = (char *) &edata;
        rc = ioctl(sock, SIOCETHTOOL, &ifr);

        if (rc == 0) {
            printf("linkstatus %d\n", edata.data);
            *plink = edata.data;
        } else {
            printf("ioctl error\n");
            ret = 0;
        }

        return ret;
    }

    int 
    getlinkspeed(unsigned long long *plinkspeed)
    {
        ethtool_gset();
        switch (edata.speed) {
            case SPEED_10: printf("10Mbps\n"); break;
            case SPEED_100: printf("100Mbps\n"); break;
            case SPEED_1000: printf("1000Mbps\n"); break;
            default: printf("speed default %d\n", edata.speed);
        }
        return 0;
    }

    int 
    getphyaddress(int *pphyaddr)
    {
        ethtool_gset();
        printf("phy addr %d\n", edata.phy_address);
        phyid = edata.phy_address;
        return 0;
    }

    int 
    getduplex(int *pduplex)
    {
    }

    int
    getautoneg(int *pautoneg)
    {
    }


    int
    miiread(int reg, u16 *pdata16)
    {
        int rc;
        struct mii_ioctl_data *pmii;
        initifr();
        pmii = (mii_ioctl_data *)(&ifr.ifr_data);
        pmii -> phy_id = phyid;
        pmii -> reg_num = reg;
        pmii -> val_in = 0;
        pmii -> val_out = 0;

        rc = ioctl(sock, SIOCGMIIREG, &ifr);

        printf("read %x from phy address %d\n", pmii -> val_out, reg);
    }

    int
    getmtu(void)
    {
        int s;
        int rc;
        initifr();
        rc = ioctl(sock, SIOCGIFMTU, &ifr);
        printf("MTU %d\n", ifr.ifr_mtu);
        return 0;
    }

    int
    setmtu()
    {
    }

    int
    miiwrite(int reg, u16 data16)
    {
        int rc;
        struct mii_ioctl_data *pmii;

        initifr();

        pmii = (mii_ioctl_data *)(&ifr.ifr_data);
        pmii -> phy_id = phyid;
        pmii -> reg_num = reg;
        pmii -> val_in = data16;
        pmii -> val_out = 0;

        rc = ioctl(sock, SIOCSMIIREG, &ifr);
        return 0;
    }

    int
    getipaddress(void)
    {
        int rc;
        initifr();
        ifr.ifr_addr.sa_family = AF_INET;
        rc = ioctl(sock, SIOCGIFADDR, &ifr);
        printf("%s\n", inet_ntoa(((struct sockaddr_in *)&ifr.ifr_addr)->sin_addr));
    }

    int
    getpermaddr(char *macaddr)
    {
        int s;
        int rc;
        initifr();
        rc = ioctl(sock, SIOCGIFHWADDR, &ifr);
        for (s=0; s<6; s++) {
            printf("%.2X ", (unsigned char)ifr.ifr_hwaddr.sa_data[s]);
        }
        printf("\n");
        return 0;
    }

};

#endif // __ETHIF_H__


#if 0

saving this for now .....


#ifndef MAX_ADDR_LEN
#define MAX_ADDR_LEN	32
#endif

int send_ioctl(struct cmd_context *ctx, void *cmd)
{
	ctx->ifr.ifr_data = (__caddr_t)cmd;
	return ioctl(ctx->fd, SIOCETHTOOL, &ctx->ifr);
}

static char *unparse_wolopts(int wolopts)
{
	static char buf[16];
	char *p = buf;

	memset(buf, 0, sizeof(buf));

	if (wolopts) {
		if (wolopts & WAKE_PHY)
			*p++ = 'p';
		if (wolopts & WAKE_UCAST)
			*p++ = 'u';
		if (wolopts & WAKE_MCAST)
			*p++ = 'm';
		if (wolopts & WAKE_BCAST)
			*p++ = 'b';
		if (wolopts & WAKE_ARP)
			*p++ = 'a';
		if (wolopts & WAKE_MAGIC)
			*p++ = 'g';
		if (wolopts & WAKE_MAGICSECURE)
			*p++ = 's';
	} else {
		*p = 'd';
	}

	return buf;
}
static int dump_wol(struct ethtool_wolinfo *wol)
{
	fprintf(stdout, "	Supports Wake-on: %s\n",
		unparse_wolopts(wol->supported));
	fprintf(stdout, "	Wake-on: %s\n",
		unparse_wolopts(wol->wolopts));
	if (wol->supported & WAKE_MAGICSECURE) {
		int i;
		int delim = 0;
		fprintf(stdout, "        SecureOn password: ");
		for (i = 0; i < SOPASS_MAX; i++) {
			fprintf(stdout, "%s%02x", delim?":":"", wol->sopass[i]);
			delim=1;
		}
		fprintf(stdout, "\n");
	}

	return 0;
}

static void dump_link_caps(const char *prefix, const char *an_prefix, u32 mask,
			   int link_mode_only);

static void dump_supported(struct ethtool_cmd *ep)
{
	u32 mask = ep->supported;

	fprintf(stdout, "	Supported ports: [ ");
	if (mask & SUPPORTED_TP)
		fprintf(stdout, "TP ");
	if (mask & SUPPORTED_AUI)
		fprintf(stdout, "AUI ");
	if (mask & SUPPORTED_BNC)
		fprintf(stdout, "BNC ");
	if (mask & SUPPORTED_MII)
		fprintf(stdout, "MII ");
	if (mask & SUPPORTED_FIBRE)
		fprintf(stdout, "FIBRE ");
	fprintf(stdout, "]\n");

	dump_link_caps("Supported", "Supports", mask, 0);
}

/* Print link capability flags (supported, advertised or lp_advertised).
 * Assumes that the corresponding SUPPORTED and ADVERTISED flags are equal.
 */
static void
dump_link_caps(const char *prefix, const char *an_prefix, u32 mask,
	       int link_mode_only)
{
	static const struct {
		int same_line; /* print on same line as previous */
		u32 value;
		const char *name;
	} mode_defs[] = {
		{ 0, ADVERTISED_10baseT_Half,       "10baseT/Half" },
		{ 1, ADVERTISED_10baseT_Full,       "10baseT/Full" },
		{ 0, ADVERTISED_100baseT_Half,      "100baseT/Half" },
		{ 1, ADVERTISED_100baseT_Full,      "100baseT/Full" },
		{ 0, ADVERTISED_1000baseT_Half,     "1000baseT/Half" },
		{ 1, ADVERTISED_1000baseT_Full,     "1000baseT/Full" },
		{ 0, ADVERTISED_1000baseKX_Full,    "1000baseKX/Full" },
		{ 0, ADVERTISED_2500baseX_Full,     "2500baseX/Full" },
		{ 0, ADVERTISED_10000baseT_Full,    "10000baseT/Full" },
		{ 0, ADVERTISED_10000baseKX4_Full,  "10000baseKX4/Full" },
		{ 0, ADVERTISED_20000baseMLD2_Full, "20000baseMLD2/Full" },
		{ 0, ADVERTISED_40000baseKR4_Full,  "40000baseKR4/Full" },
		{ 0, ADVERTISED_40000baseCR4_Full,  "40000baseCR4/Full" },
		{ 0, ADVERTISED_40000baseSR4_Full,  "40000baseSR4/Full" },
		{ 0, ADVERTISED_40000baseLR4_Full,  "40000baseLR4/Full" },
	};
	int indent;
	int did1, new_line_pend, i;

	/* Indent just like the separate functions used to */
	indent = strlen(prefix) + 14;
	if (indent < 24)
		indent = 24;

	fprintf(stdout, "	%s link modes:%*s", prefix,
		indent - (int)strlen(prefix) - 12, "");
	did1 = 0;
	new_line_pend = 0;
	for (i = 0; i < ARRAY_SIZE(mode_defs); i++) {
		if (did1 && !mode_defs[i].same_line)
		if (did1 && !mode_defs[i].same_line)
			new_line_pend = 1;
		if (mask & mode_defs[i].value) {
			if (new_line_pend) {
				fprintf(stdout, "\n");
				fprintf(stdout, "	%*s", indent, "");
				new_line_pend = 0;
			}
			did1++;
			fprintf(stdout, "%s ", mode_defs[i].name);
		}
	}
	if (did1 == 0)
		 fprintf(stdout, "Not reported");
	fprintf(stdout, "\n");

	if (!link_mode_only) {
		fprintf(stdout, "	%s pause frame use: ", prefix);
		if (mask & ADVERTISED_Pause) {
			fprintf(stdout, "Symmetric");
			if (mask & ADVERTISED_Asym_Pause)
				fprintf(stdout, " Receive-only");
			fprintf(stdout, "\n");
		} else {
			if (mask & ADVERTISED_Asym_Pause)
				fprintf(stdout, "Transmit-only\n");
			else
				fprintf(stdout, "No\n");
		}

		fprintf(stdout, "	%s auto-negotiation: ", an_prefix);
		if (mask & ADVERTISED_Autoneg)
			fprintf(stdout, "Yes\n");
		else
			fprintf(stdout, "No\n");
	}
}
static int dump_ecmd(struct ethtool_cmd *ep)
{
	u32 speed;

	dump_supported(ep);
	dump_link_caps("Advertised", "Advertised", ep->advertising, 0);
	if (ep->lp_advertising)
		dump_link_caps("Link partner advertised",
			       "Link partner advertised", ep->lp_advertising,
			       0);

	fprintf(stdout, "	Speed: ");
	speed = ethtool_cmd_speed(ep);
	if (speed == 0 || speed == (u16)(-1) || speed == (u32)(-1))
		fprintf(stdout, "Unknown!\n");
	else
		fprintf(stdout, "%uMb/s\n", speed);

	fprintf(stdout, "	Duplex: ");
	switch (ep->duplex) {
	case DUPLEX_HALF:
		fprintf(stdout, "Half\n");
		break;
	case DUPLEX_FULL:
		fprintf(stdout, "Full\n");
		break;
	default:
		fprintf(stdout, "Unknown! (%i)\n", ep->duplex);
		break;
	};

	fprintf(stdout, "	Port: ");
	switch (ep->port) {
	case PORT_TP:
		fprintf(stdout, "Twisted Pair\n");
		break;
	case PORT_AUI:
		fprintf(stdout, "AUI\n");
		break;
	case PORT_BNC:
		fprintf(stdout, "BNC\n");
		break;
	case PORT_MII:
		fprintf(stdout, "MII\n");
		break;
	case PORT_FIBRE:
		fprintf(stdout, "FIBRE\n");
		break;
	case PORT_DA:
		fprintf(stdout, "Direct Attach Copper\n");
		break;
	case PORT_NONE:
		fprintf(stdout, "None\n");
		break;
	case PORT_OTHER:
		fprintf(stdout, "Other\n");
		break;
	default:
		fprintf(stdout, "Unknown! (%i)\n", ep->port);
		break;
	};

	fprintf(stdout, "	PHYAD: %d\n", ep->phy_address);
	fprintf(stdout, "	Transceiver: ");
	switch (ep->transceiver) {
	case XCVR_INTERNAL:
		fprintf(stdout, "internal\n");
		break;
	case XCVR_EXTERNAL:
		fprintf(stdout, "external\n");
		break;
	default:
		fprintf(stdout, "Unknown!\n");
		break;
	};

	fprintf(stdout, "	Auto-negotiation: %s\n",
		(ep->autoneg == AUTONEG_DISABLE) ?
		"off" : "on");

	if (ep->port == PORT_TP) {
		fprintf(stdout, "	MDI-X: ");
		if (ep->eth_tp_mdix_ctrl == ETH_TP_MDI) {
			fprintf(stdout, "off (forced)\n");
		} else if (ep->eth_tp_mdix_ctrl == ETH_TP_MDI_X) {
			fprintf(stdout, "on (forced)\n");
		} else {
			switch (ep->eth_tp_mdix) {
			case ETH_TP_MDI:
				fprintf(stdout, "off");
				break;
			case ETH_TP_MDI_X:
				fprintf(stdout, "on");
				break;
			default:
				fprintf(stdout, "Unknown");
				break;
			}
			if (ep->eth_tp_mdix_ctrl == ETH_TP_MDI_AUTO)
				fprintf(stdout, " (auto)");
			fprintf(stdout, "\n");
		}
	}

	return 0;
}

static int do_gset(struct cmd_context *ctx)
{
	int err;
	struct ethtool_cmd ecmd;
	struct ethtool_wolinfo wolinfo;
	struct ethtool_value edata;
	int allfail = 1;

	fprintf(stdout, "Settings for %s:\n", ctx->devname);

	ecmd.cmd = ETHTOOL_GSET;
	err = send_ioctl(ctx, &ecmd);
    if (err==0) {
		err = dump_ecmd(&ecmd);
		if (err)
			return err;
		allfail = 0;
	} else if (errno != EOPNOTSUPP) {
		perror("Cannot get device settings");
	}

	wolinfo.cmd = ETHTOOL_GWOL;
	err = send_ioctl(ctx, &wolinfo);
	if (err == 0) {
		err = dump_wol(&wolinfo);
		if (err)
			return err;
		allfail = 0;
	} else if (errno != EOPNOTSUPP) {
		perror("Cannot get wake-on-lan settings");
	}

	edata.cmd = ETHTOOL_GLINK;
	err = send_ioctl(ctx, &edata);
	if (err == 0) {
		fprintf(stdout, "	Link detected: %s\n",
			edata.data ? "yes":"no");
		allfail = 0;
	} else if (errno != EOPNOTSUPP) {
		perror("Cannot get link status");
	}

	if (allfail) {
		fprintf(stdout, "No data available\n");
		return 75;
	}
	return 0;
}

#endif
