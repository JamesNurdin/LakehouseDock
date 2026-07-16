WITH sales_union AS (
    SELECT 
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_call_center_sk AS channel_sk,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_store_sk,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_web_page_sk,
        'web' AS channel
    FROM web_sales ws
),
item_sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        s.channel,
        SUM(s.quantity) AS total_qty,
        SUM(s.net_paid) AS total_paid,
        SUM(s.net_profit) AS total_profit,
        COUNT(DISTINCT s.item_sk) AS distinct_items
    FROM sales_union s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_brand, s.channel
),
item_sales_rn AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year, i_category ORDER BY total_paid DESC) AS rn
    FROM item_sales_agg
),
top_items AS (
    SELECT *
    FROM item_sales_rn
    WHERE rn <= 5
),
call_center_performance AS (
    SELECT
        cc.cc_call_center_id,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_cs_paid,
        CASE 
            WHEN cc.cc_tax_percentage > 0 
            THEN COALESCE(SUM(cs.cs_net_paid), 0) * (1 - cc.cc_tax_percentage / 100) 
            ELSE NULL
        END AS net_after_tax
    FROM call_center cc
    LEFT JOIN catalog_sales cs ON cc.cc_call_center_sk = cs.cs_call_center_sk
    GROUP BY cc.cc_call_center_id, cc.cc_tax_percentage
),
call_center_summary AS (
    SELECT 
        SUM(total_cs_paid) AS overall_total_cs_paid,
        SUM(net_after_tax) AS overall_net_after_tax
    FROM call_center_performance
),
customer_lifetime_value AS (
    SELECT
        c.c_customer_id,
        SUM(COALESCE(s.total_paid, 0)) AS lifetime_sales,
        SUM(COALESCE(s.total_profit, 0)) AS lifetime_profit,
        MIN(d.d_date) AS first_purchase,
        MAX(d.d_date) AS last_purchase,
        CASE WHEN COUNT(*) > 0 THEN SUM(COALESCE(s.total_paid, 0)) / COUNT(*) ELSE 0 END AS avg_spend_per_txn
    FROM customer c
    LEFT JOIN (
        SELECT 
            cs.cs_bill_customer_sk AS cust_sk,
            cs.cs_net_paid AS total_paid,
            cs.cs_net_profit AS total_profit,
            cs.cs_sold_date_sk AS date_sk
        FROM catalog_sales cs
        UNION ALL
        SELECT 
            ss.ss_customer_sk,
            ss.ss_net_paid,
            ss.ss_net_profit,
            ss.ss_sold_date_sk
        FROM store_sales ss
        UNION ALL
        SELECT 
            ws.ws_bill_customer_sk,
            ws.ws_net_paid,
            ws.ws_net_profit,
            ws.ws_sold_date_sk
        FROM web_sales ws
    ) s ON c.c_customer_sk = s.cust_sk
    LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
    GROUP BY c.c_customer_id
    HAVING SUM(COALESCE(s.total_paid, 0)) > 1000
),
final_report AS (
    SELECT
        ti.d_year,
        ti.i_category,
        ti.i_brand,
        ti.channel,
        ti.total_qty,
        ti.total_paid,
        ti.total_profit,
        ti.distinct_items,
        ti.rn,
        ROW_NUMBER() OVER (PARTITION BY ti.d_year ORDER BY ti.total_paid DESC) AS rank_in_year,
        oc.overall_total_cs_paid,
        oc.overall_net_after_tax,
        clv.c_customer_id,
        clv.lifetime_sales,
        clv.lifetime_profit,
        clv.first_purchase,
        clv.last_purchase,
        clv.avg_spend_per_txn,
        CONCAT(ti.i_category, ' - ', ti.i_brand) AS category_brand,
        CASE 
            WHEN ti.total_profit > 0 THEN 'POSITIVE'
            WHEN ti.total_profit < 0 THEN 'NEGATIVE'
            ELSE 'ZERO'
        END AS profit_sign,
        COALESCE(NULLIF(ti.total_paid, 0), 1) / NULLIF(ti.total_qty, 0) AS avg_price_per_qty,
        REGEXP_REPLACE(LOWER(ti.i_brand), '\\s+', '') AS brand_normalized,
        (SELECT COUNT(DISTINCT cc2.cc_call_center_id)
         FROM call_center cc2
         JOIN catalog_sales cs2 ON cc2.cc_call_center_sk = cs2.cs_call_center_sk
         JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
         WHERE i2.i_category = ti.i_category AND i2.i_brand = ti.i_brand) AS distinct_cc_count,
        (SELECT SUM(ti2.total_profit)
         FROM top_items ti2
         WHERE ti2.i_category = ti.i_category
           AND ti2.d_year = ti.d_year - 1) AS prev_year_profit,
        CASE 
            WHEN (SELECT SUM(ti2.total_profit)
                  FROM top_items ti2
                  WHERE ti2.i_category = ti.i_category
                    AND ti2.d_year = ti.d_year - 1) > 0
            THEN ((ti.total_profit - 
                  (SELECT SUM(ti2.total_profit)
                   FROM top_items ti2
                   WHERE ti2.i_category = ti.i_category
                     AND ti2.d_year = ti.d_year - 1))
                  / (SELECT SUM(ti2.total_profit)
                     FROM top_items ti2
                     WHERE ti2.i_category = ti.i_category
                       AND ti2.d_year = ti.d_year - 1)) * 100
            ELSE NULL
        END AS profit_change_pct
    FROM top_items ti
    LEFT JOIN call_center_summary oc ON 1 = 1
    LEFT JOIN customer_lifetime_value clv 
        ON ti.rn = 1 AND clv.lifetime_sales > ti.total_paid
)
SELECT *
FROM final_report
WHERE profit_sign = 'POSITIVE'
  AND (total_qty IS NOT NULL OR rn = 1)
ORDER BY d_year DESC, total_paid DESC
LIMIT 100
