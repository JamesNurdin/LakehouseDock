-- Goal: Identify call centers with strong sales performance after excluding those managed by a specific manager, combine two complementary high‑value filters, and finally remove low‑discount groups.
WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        cd.cd_credit_rating,
        SUM(ss.ss_net_paid) AS total_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE td.t_hour BETWEEN 9 AND 17                                   -- business hours
      AND cd.cd_credit_rating IN ('Good', 'Low Risk')                 -- credit quality filter
      AND cc.cc_zip = '85804'                                         -- specific zip code
      AND ss.ss_ext_list_price > 500                                   -- high list price sales
      AND ss.ss_quantity >= 2                                          -- minimum quantity per line
    GROUP BY cc.cc_call_center_id, cd.cd_credit_rating
),
high_profit_cc AS (
    SELECT DISTINCT cc_call_center_id
    FROM call_center
    WHERE cc_manager = 'Jack Little'
),
filtered_sales AS (
    SELECT
        sa.cc_call_center_id,
        sa.cd_credit_rating,
        sa.total_paid,
        sa.distinct_tickets,
        sa.total_discount,
        CASE WHEN sa.total_discount > 1000 THEN 'HIGH_DISCOUNT' ELSE 'LOW_DISCOUNT' END AS discount_level
    FROM sales_agg sa
    WHERE sa.cc_call_center_id NOT IN (SELECT cc_call_center_id FROM high_profit_cc)  -- anti‑semi join
),
unioned AS (
    SELECT cc_call_center_id, discount_level, total_paid
    FROM filtered_sales
    WHERE total_paid > 10000
    UNION DISTINCT
    SELECT cc_call_center_id, discount_level, total_paid
    FROM filtered_sales
    WHERE distinct_tickets > 100
),
final_set AS (
    SELECT *
    FROM unioned
    EXCEPT
    SELECT cc_call_center_id, discount_level, total_paid
    FROM unioned
    WHERE discount_level = 'LOW_DISCOUNT'
)
SELECT
    cc_call_center_id,
    discount_level,
    total_paid
FROM final_set
ORDER BY total_paid DESC
LIMIT 100
