WITH agg AS (
    SELECT
        cp.cp_department AS cp_department,
        cp.cp_type AS cp_type,
        ws.web_state AS web_state,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_coupon_amt) AS total_coupon
    FROM catalog_page cp
    JOIN store_sales ss
        ON cp.cp_start_date_sk = ss.ss_sold_date_sk
    JOIN web_site ws
        ON cp.cp_end_date_sk = ws.web_open_date_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND cp.cp_type = 'monthly'
      AND ws.web_country = 'United States'
    GROUP BY cp.cp_department, cp.cp_type, ws.web_state
    HAVING SUM(ss.ss_net_paid) > 10000
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_net_profit DESC) AS dept_profit_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
