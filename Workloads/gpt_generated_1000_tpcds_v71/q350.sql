WITH filtered AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        ss.ss_ext_wholesale_cost,
        ss.ss_net_profit,
        p.p_promo_name,
        p.p_channel_dmail,
        p.p_channel_email,
        p.p_end_date_sk,
        p.p_discount_active
    FROM tpcds.store_sales AS ss
    JOIN tpcds.promotion AS p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_dmail = 'Y'
      AND p.p_channel_email = 'N'
      AND p.p_end_date_sk BETWEEN 2450300 AND 2450600
      AND ss.ss_ext_wholesale_cost > 1000
      AND ss.ss_ext_tax < 50
      AND ss.ss_sold_time_sk BETWEEN 40000 AND 80000
),
aggregated AS (
    SELECT
        f.p_channel_dmail,
        f.p_channel_email,
        f.ss_store_sk,
        SUM(f.ss_quantity) AS total_quantity,
        SUM(f.ss_ext_sales_price) AS total_sales,
        SUM(f.ss_net_profit) AS total_profit
    FROM filtered AS f
    GROUP BY GROUPING SETS (
        (f.p_channel_dmail, f.p_channel_email, f.ss_store_sk),
        (f.p_channel_dmail, f.p_channel_email),
        (f.p_channel_dmail),
        ()
    )
)
SELECT
    a.p_channel_dmail,
    a.p_channel_email,
    a.ss_store_sk,
    a.total_quantity,
    a.total_sales,
    a.total_profit,
    RANK() OVER (PARTITION BY a.p_channel_dmail ORDER BY a.total_profit DESC) AS profit_rank
FROM aggregated AS a
ORDER BY a.p_channel_dmail, profit_rank
LIMIT 100
