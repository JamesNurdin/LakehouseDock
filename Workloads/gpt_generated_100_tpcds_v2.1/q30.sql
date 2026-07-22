WITH store_sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        p.p_promo_id AS promo_id,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS txn_count,
        CASE WHEN SUM(ss.ss_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2002
      AND p.p_discount_active = 'Y'
      AND ss.ss_net_paid > 0
      AND EXISTS (
          SELECT 1
          FROM date_dim d_start
          WHERE d_start.d_date_sk = p.p_start_date_sk
            AND d_start.d_date <= d.d_date
      )
      AND EXISTS (
          SELECT 1
          FROM date_dim d_end
          WHERE d_end.d_date_sk = p.p_end_date_sk
            AND d_end.d_date >= d.d_date
      )
    GROUP BY d.d_date, p.p_promo_id
),
web_sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        p.p_promo_id AS promo_id,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS txn_count,
        CASE WHEN SUM(ws.ws_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2002
      AND p.p_discount_active = 'Y'
      AND ws.ws_net_paid > 0
      AND EXISTS (
          SELECT 1
          FROM date_dim d_start
          WHERE d_start.d_date_sk = p.p_start_date_sk
            AND d_start.d_date <= d.d_date
      )
      AND EXISTS (
          SELECT 1
          FROM date_dim d_end
          WHERE d_end.d_date_sk = p.p_end_date_sk
            AND d_end.d_date >= d.d_date
      )
    GROUP BY d.d_date, p.p_promo_id
),
combined_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
final_agg AS (
    SELECT
        sale_date,
        promo_id,
        profit_category,
        SUM(total_net_paid) AS total_net_paid,
        SUM(total_net_profit) AS total_net_profit,
        SUM(txn_count) AS txn_count
    FROM combined_sales
    GROUP BY sale_date, promo_id, profit_category
)
SELECT
    sale_date,
    promo_id,
    profit_category,
    total_net_paid,
    total_net_profit,
    txn_count,
    ROW_NUMBER() OVER (PARTITION BY profit_category ORDER BY total_net_paid DESC) AS rank_by_category,
    (SELECT AVG(total_net_profit) FROM final_agg) AS avg_net_profit_year
FROM final_agg
ORDER BY total_net_paid DESC
LIMIT 100
