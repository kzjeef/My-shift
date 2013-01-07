#include "tables.h"

typedef struct {
int year, month, day, hour, weekday;
int leap;	/* the lunar month is a leap month */
} Date;

typedef char byte;

static int daysInSolarMonth[13] = {
    0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};

static int moon[2] = {29,30}; /* a short (long) lunar month has 29 (30) days */

static	char	*Gan[] = {
	"Jia3",	"Yi3",	 "Bing3", "Ding1", "Wu4",
	"Ji3",	"Geng1", "Xin1",  "Ren2",  "Gui3"
};

static	char	*Zhi[] = {
	"Zi3",	"Chou3", "Yin2",  "Mao3",  "Chen2", "Si4",
	"Wu3",	"Wei4",	 "Shen1", "You3",  "Xu1",   "Hai4"
};

static	char   *ShengXiao[] = {
    "Mouse", "Ox", "Tiger", "Rabbit", "Dragon", "Snake",
    "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"
};

static char *weekday[] = {
    "Sunday", "Monday", "Tuesday", "Wednesday",
    "Thursday", "Friday", "Saturday"
};

static	char	*GanGB[] = {
    "甲", "乙", "丙", "丁", "戊",
    "己", "庚", "辛", "壬", "癸"
};

static	char	*ZhiGB[] = {
    "子", "丑", "寅", "卯", "辰", "巳",
    "午", "未", "申", "酉", "戌", "亥"
};

static	char   *ShengXiaoGB[] = {
    "鼠", "牛", "虎", "兔", "龙", "蛇",
    "马", "羊", "猴", "鸡", "狗", "猪"
};

static char *weekdayGB[] = {
    "日", "一", "二", "三",
    "四", "五", "六"
};

int ymonth[Nyear];	/* number of lunar months in the years */
int yday[Nyear];	/* number of lunar days in the years */
int mday[Nmonth+1];	/* number of days in the months of the lunar year */
int jieAlert;		/* if there is uncertainty in JieQi calculation */


void	Solar2Lunar(), Lunar2Solar();
long    Solar2Day(), Solar2Day1(), Lunar2Day();
void	Day2Lunar(), Day2Solar();
int     make_yday(), make_mday(), GZcycle();
void	CalGZ();
int	JieDate(), JieDate();
void    readBM(), display3();
void	Report(), ReportE(), ReportBM(), ReportGB();
void	usage(), Error();


void Solar2Lunar()
{

    long offset;
    Date *d;

    offset = Solar2Day(&solar);
    solar.weekday = (offset + SolarFirstDate.weekday) % 7;
    
    /* A lunar day begins at 11 p.m. */
    if (solar.hour == 23)
	offset++;

    Day2Lunar(offset, &lunar);
    lunar.hour = solar.hour;
    CalGZ(offset, &lunar, &gan, &zhi);

    jieAlert = JieDate(&solar, &lunar2);
    lunar2.day = lunar.day;
    lunar2.hour = lunar.hour;
    CalGZ(offset, &lunar2, &gan2, &zhi2);
}



void Lunar2Solar()
{
    long offset;
    int adj;
    Date *d;

    /* A solar day begins at 12 a.m. */
    adj = (lunar.hour == 23)? -1 : 0;
    offset = Lunar2Day(&lunar);
    solar.weekday = (offset+ adj + SolarFirstDate.weekday) % 7;
    Day2Solar(offset + adj, &solar);
    solar.hour = lunar.hour;
    CalGZ(offset, &lunar, &gan, &zhi);

    jieAlert = JieDate(&solar, &lunar2);
    lunar2.day = lunar.day;
    lunar2.hour = lunar.hour;
    CalGZ(offset, &lunar2, &gan2, &zhi2);
}

#define	LeapYear(y)	(((y)%4==0) && ((y)%100!=0) || ((y)%400==0))
#define BYEAR		1201
/* BYEAR % 4 == 1  and BYEAR % 400 == 1 for easy calculation of leap years */
/* assert(BYEAR <= SolarFirstDate.year) */


long Solar2Day(d)
Date *d;
{
    return (Solar2Day1(d) - Solar2Day1(&SolarFirstDate));
}


/* Compute the number of days from the Solar date BYEAR.1.1 */
long Solar2Day1(d)
Date *d;
{
    long offset, delta;
    int i;

    delta = d->year - BYEAR;
    if (delta<0) Error("Internal error: pick a larger constant for BYEAR.");
    offset = delta * 365 + delta / 4 - delta / 100 + delta / 400;
    for (i=1; i< d->month; i++)
    	offset += daysInSolarMonth[i];
    if ((d->month > 2) && LeapYear(d->year))
	offset++;
    offset += d->day - 1;

    if ((d->month == 2) && LeapYear(d->year))
    {
	if (d->day > 29) Error("Day out of range.");
    }
    else if (d->day > daysInSolarMonth[d->month]) Error("Day out of range.");
    return offset;
}

/* Compute offset days of a lunar date from the beginning of the table */
long Lunar2Day(d)
Date *d;
{
    long offset = 0;
    int year, i, m, nYear, leapMonth;

    nYear = make_yday();
    year = d->year - LunarFirstDate.year;
    for (i=0; i<year; i++)
	offset += yday[i];

    leapMonth = make_mday(year);
    if ((d->leap) && (leapMonth!=d->month))
    {
	printf("%d is not a leap month in year %d.\n", d->month, d->year);
	exit(1);
    }
    for (m=1; m<d->month; m++)
	offset += mday[m];
    if (leapMonth && 
	((d->month>leapMonth) || (d->leap && (d->month==leapMonth))))
	offset += mday[m++];
    offset += d->day - 1;

    if (d->day > mday[m]) Error("Day out of range.");

    return offset;
}

void Day2Lunar(offset, d)
long offset;
Date *d;

{
    int i, m, nYear, leapMonth;
    
    nYear = make_yday();
    for (i=0; i<nYear && offset > 0; i++)
	offset -= yday[i];
    if (offset<0)
	offset += yday[--i];
    if (i==Nyear) Error("Year out of range.");
    d->year = i + LunarFirstDate.year;

    leapMonth = make_mday(i);
    for (m=1; m<=Nmonth && offset>0; m++)
	offset -= mday[m];
    if (offset<0)
	offset += mday[--m];

    d->leap = 0;	/* don't know leap or not yet */

    if (leapMonth>0)	/* has leap month */
    {
	/* if preceeding month number is the leap month,
	   this month is the actual extra leap month */
	d->leap = (leapMonth == (m - 1));

	/* month > leapMonth is off by 1, so adjust it */
	if (m > leapMonth) --m;
    }

    d->month = m;
    d->day = offset + 1;
}

void Day2Solar(offset, d)
long offset;
Date *d;
{
    int	i, m, days;

    /* offset is the number of days from SolarFirstDate */
    offset -= Solar2Day(&LunarFirstDate);  /* the argument is negative */
    /* offset is now the number of days from SolarFirstDate.year.1.1 */

    for (i=SolarFirstDate.year;
         (i<SolarFirstDate.year+Nyear) && (offset > 0);	 i++) 
	offset -= 365 + LeapYear(i);
    if (offset<0)
    {
	--i; 	/* LeapYear is a macro */
	offset += 365 + LeapYear(i);
    }
    if (i==(SolarFirstDate.year + Nyear)) Error("Year out of range.");
    d->year = i;
    
    /* assert(offset<(365+LeapYear(i))); */
    for (m=1; m<=12; m++)
    {
	days = daysInSolarMonth[m];
	if ((m==2) && LeapYear(i))	/* leap February */
	    days++;
	if (offset<days)
	{
	    d->month = m;
	    d->day = offset + 1;
	    return;
	}
	offset -= days;
    }
}

int GZcycle(g, z)
int g, z;
{
    int gz;

    for (gz = z; gz % 10 != g && gz < 60; gz += 12) ;
    if (gz >= 60) printf("internal error\n");
    return gz+1;
}

void CalGZ(offset, d, g, z)
long offset;
Date *d, *g, *z;
{
    int	year, month;
        
    year = d->year - LunarFirstDate.year;
    month = year * 12 + d->month - 1;   /* leap months do not count */

    g->year = (GanFirstDate.year + year) % 10;
    z->year = (ZhiFirstDate.year + year) % 12;
    g->month = (GanFirstDate.month + month) % 10;
    z->month = (ZhiFirstDate.month + month) % 12;
    g->day = (GanFirstDate.day + offset) % 10;
    z->day = (ZhiFirstDate.day + offset) % 12;
    z->hour = ((d->hour + 1) / 2) % 12;
    g->hour = (g->day * 12 + z->hour) % 10;
}

/* Compare two dates and return <,=,> 0 if the 1st is <,=,> the 2nd */
int CmpDate(month1, day1, month2, day2)
int month1, day1, month2, day2;
{
    if (month1!=month2) return(month1-month2);
    if (day1!=day2) return(day1-day2);
    return(0);
}

/*
   Given a solar date, find the "lunar" date for the purpose of
   calculating the "4-columns" by taking jie into consideration.
*/
int JieDate(ds, dl)
Date *ds, *dl;
{
    int m, flag;

    if (ds->month==1)
    {
	flag = CmpDate(ds->month, ds->day,
		       1, fest[ds->year - SolarFirstDate.year - 1][11]);
	if (flag<0) dl->month = 11;
	else if (flag>0) dl->month = 12;
	dl->year = ds->year - 1;
	return(flag==0);
    }
    for (m=2; m<=12; m++)
    {
	flag = CmpDate(ds->month, ds->day,
		       m, fest[ds->year - SolarFirstDate.year][m-2]);
	if (flag==0) m++;
	if (flag<=0) break;
    }
    dl->month = (m-2) % 12;
    dl->year = ds->year;
    if ((dl->month)==0)
    {
	dl->year = ds->year - 1;
	dl->month = 12;
    }
    return(flag==0);
}



/* Compute the number of days in each lunar year in the table */
int make_yday()
{
    int year, i, leap;
    long code;
    
    for (year = 0; year < Nyear; year++)
    {
	code = yearInfo[year];
	leap = code & 0xf;
	yday[year] = 0;
	if (leap != 0)
	{
	    i = (code >> 16) & 0x1;
	    yday[year] += moon[i];
	}
	code >>= 4;
	for (i = 0; i < Nmonth-1; i++)
	{
	    yday[year] += moon[code&0x1];
	    code >>= 1;
	}
	ymonth[year] = 12;
	if (leap != 0) ymonth[year]++;
    }
    return Nyear;
}


/* Compute the days of each month in the given lunar year */
int make_mday(year)
int year;
{
    int i, leapMonth;
    long code;
    
    code = yearInfo[year];
    leapMonth = code & 0xf;
    /* leapMonth == 0 means no leap month */
    code >>= 4;
    if (leapMonth == 0)
    {
	mday[Nmonth] = 0;
	for (i = Nmonth-1; i >= 1; i--)
	{
	    mday[i] = moon[code&0x1];
	    code >>= 1;
	}
    }
    else
    {
	/* 
	  There is a leap month (run4 yue4) L in this year.
	  mday[1] contains the number of days in the 1-st month;
	  mday[L] contains the number of days in the L-th month;
	  mday[L+1] contains the number of days in the L-th leap month;
	  mday[L+2] contains the number of days in the L+1 month, etc.

	  cf. yearInfo[]: info about the leap month is encoded differently.
	*/
	i = (yearInfo[year] >> 16) & 0x1;
	mday[leapMonth+1] = moon[i];
	for (i = Nmonth; i >= 1; i--)
	{
	    if (i == leapMonth+1) i--;
	    mday[i] = moon[code&0x1];
	    code >>= 1;
	}
    }
    return leapMonth;
}
