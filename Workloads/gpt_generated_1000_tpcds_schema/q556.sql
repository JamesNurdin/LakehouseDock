/* goal: Analyze net revenue and coupon behavior by call center and hour, filtering on high‑value sales, specific market segments, and promotion channels, while demonstrating advanced SQL features (CTE, subquery, UNION, GROUPING SETS, HAVING). */
WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_net_paid_inc_tax,
        cs.cs_coupon_amt,
        cs.cs_ext_wholesale_cost,
        cs.cs_quantity,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_tax > 500                     -- filter 1
      AND cs.cs_quantity >= 2                              -- filter 2
      AND EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_promo_sk = cs.cs_promo_sk
              AND p.p_cost > 800                         -- filter 3 (realistic literal)
              AND p.p_channel_event = 'N'                -- filter 4
        )
),
agg_a AS (
    SELECT
        cc.cc_call_center_id,
        td.t_hour,
        SUM(fs.cs_net_paid_inc_tax) AS total_net_paid,
        AVG(fs.cs_coupon_amt)       AS avg_coupon,
        COUNT(*)                    AS sales_cnt,
        MIN(fs.cs_ext_wholesale_cost) AS min_wholesale,
        MAX(fs.cs_ext_wholesale_cost) AS max_wholesale
    FROM filtered_sales fs
    JOIN call_center cc        ON fs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td           ON fs.cs_sold_time_sk   = td.t_time_sk
    JOIN promotion p           ON fs.cs_promo_sk       = p.p_promo_sk
    JOIN customer_demographics cd ON fs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_sq_ft > 300000000                     -- realistic numeric filter
      AND td.t_am_pm = 'PM'                           -- realistic literal
      AND cd.cd_purchase_estimate >= 5000
      AND p.p_channel_demo = 'N'
    GROUP BY GROUPING SETS (
        (cc.cc_call_center_id, td.t_hour),
        (cc.cc_call_center_id),
        (td.t_hour),
        ()
    )
    HAVING SUM(fs.cs_net_paid_inc_tax) > 1000
),
agg_b AS (
    SELECT
        cc.cc_call_center_id,
        td.t_hour,
        SUM(fs.cs_net_paid_inc_tax) AS total_net_paid,
        AVG(fs.cs_coupon_amt)       AS avg_coupon,
        COUNT(*)                    AS sales_cnt,
        MIN(fs.cs_ext_wholesale_cost) AS min_wholesale,
        MAX(fs.cs_ext_wholesale_cost) AS max_wholesale
    FROM filtered_sales fs
    JOIN call_center cc        ON fs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td           ON fs.cs_sold_time_sk   = td.t_time_sk
    JOIN promotion p           ON fs.cs_promo_sk       = p.p_promo_sk
    JOIN customer_demographics cd ON fs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_sq_ft < 0                               -- alternate filter branch
      AND td.t_am_pm = 'AM'
      AND cd.cd_purchase_estimate < 5000
      AND p.p_channel_event = 'N'
    GROUP BY GROUPING SETS (
        (cc.cc_call_center_id, td.t_hour),
        (cc.cc_call_center_id),
        (td.t_hour),
        ()
    )
    HAVING SUM(fs.cs_net_paid_inc_tax) > 500
)
SELECT *
FROM agg_a
UNION
SELECT *
FROM agg_b
ORDER BY total_net_paid DESC
LIMIT 100
