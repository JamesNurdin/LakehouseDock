WITH agg AS (
    SELECT
        p.p_promo_name,
        i.i_brand,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        GROUPING(p.p_promo_name) AS g_promo,
        GROUPING(i.i_brand) AS g_brand
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    WHERE td.t_shift = 'first'
      AND i.i_manufact = 'esen stable'
      AND hd.hd_income_band_sk = 11
      AND cs.cs_ext_sales_price > 1000
    GROUP BY GROUPING SETS (
        (p.p_promo_name, i.i_brand),
        (p.p_promo_name),
        (i.i_brand),
        ()
    )
)
SELECT
    p_promo_name,
    i_brand,
    total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
