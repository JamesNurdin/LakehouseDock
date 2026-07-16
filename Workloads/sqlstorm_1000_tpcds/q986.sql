WITH
month_list AS (
    SELECT DISTINCT d.d_year, d.d_moy AS sales_month
    FROM date_dim d
    WHERE d.d_year BETWEEN 2000 AND 2002
),
customer_base AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM customer c
),
store_sales_pre AS (
    SELECT
        ss.ss_ticket_number AS order_number,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        CASE WHEN ss.ss_net_paid = 0 THEN NULL ELSE ss.ss_net_profit / ss.ss_net_paid END AS net_margin,
        d.d_year,
        d.d_moy AS sales_month,
        i.i_category,
        i.i_item_id,
        i.i_product_name,
        CONCAT(i.i_product_name, ' (', i.i_category, ')') AS product_label,
        COALESCE(sr.sr_net_loss, 0) AS return_loss
    FROM store_sales ss
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    WHERE d.d_year BETWEEN 2000 AND 2002
),
catalog_sales_pre AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        CASE WHEN cs.cs_net_paid = 0 THEN NULL ELSE cs.cs_net_profit / cs.cs_net_paid END AS net_margin,
        d.d_year,
        d.d_moy AS sales_month,
        i.i_category,
        i.i_item_id,
        i.i_product_name,
        CONCAT(i.i_product_name, ' (', i.i_category, ')') AS product_label,
        COALESCE(cr.cr_net_loss, 0) AS return_loss
    FROM catalog_sales cs
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    WHERE d.d_year BETWEEN 2000 AND 2002
),
web_sales_pre AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        CASE WHEN ws.ws_net_paid = 0 THEN NULL ELSE ws.ws_net_profit / ws.ws_net_paid END AS net_margin,
        d.d_year,
        d.d_moy AS sales_month,
        i.i_category,
        i.i_item_id,
        i.i_product_name,
        CONCAT(i.i_product_name, ' (', i.i_category, ')') AS product_label,
        COALESCE(wr.wr_net_loss, 0) AS return_loss
    FROM web_sales ws
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE d.d_year BETWEEN 2000 AND 2002
),
all_sales AS (
    SELECT * FROM store_sales_pre
    UNION ALL
    SELECT * FROM catalog_sales_pre
    UNION ALL
    SELECT * FROM web_sales_pre
),
customer_monthly_sales AS (
    SELECT
        cb.c_customer_sk,
        cb.c_customer_id,
        cb.full_name,
        cb.c_preferred_cust_flag,
        ml.d_year,
        ml.sales_month,
        COALESCE(SUM(a.quantity), 0) AS total_quantity,
        COALESCE(SUM(a.net_paid), 0) AS total_sales,
        COALESCE(SUM(a.net_profit - a.return_loss), 0) AS net_profit_adj,
        COUNT(DISTINCT a.order_number) AS distinct_orders,
        SUM(CASE WHEN a.return_loss > 0 THEN 1 ELSE 0 END) AS returns_count,
        COALESCE(AVG(a.net_margin), 0) AS avg_net_margin
    FROM customer_base cb
    CROSS JOIN month_list ml
    LEFT JOIN all_sales a
        ON cb.c_customer_sk = a.customer_sk
        AND a.d_year = ml.d_year
        AND a.sales_month = ml.sales_month
    GROUP BY
        cb.c_customer_sk,
        cb.c_customer_id,
        cb.full_name,
        cb.c_preferred_cust_flag,
        ml.d_year,
        ml.sales_month
),
ranked_customers AS (
    SELECT
        cms.*,
        ROW_NUMBER() OVER (PARTITION BY cms.d_year, cms.sales_month ORDER BY cms.net_profit_adj DESC) AS profit_rank,
        AVG(cms.net_profit_adj) OVER (PARTITION BY cms.d_year, cms.sales_month) AS avg_monthly_profit,
        (SELECT AVG(cms2.net_profit_adj)
         FROM customer_monthly_sales cms2
         WHERE cms2.d_year = cms.d_year
           AND cms2.sales_month = cms.sales_month
           AND cms2.c_customer_sk <> cms.c_customer_sk) AS avg_other_profit
    FROM customer_monthly_sales cms
),
final_result AS (
    SELECT
        rc.c_customer_id,
        rc.full_name,
        rc.d_year,
        rc.sales_month,
        rc.total_sales,
        rc.net_profit_adj,
        rc.total_quantity,
        rc.distinct_orders,
        rc.returns_count,
        rc.avg_net_margin,
        rc.profit_rank,
        rc.avg_monthly_profit,
        rc.avg_other_profit,
        CASE
            WHEN rc.net_profit_adj > rc.avg_monthly_profit THEN 'Above Avg'
            WHEN rc.net_profit_adj < rc.avg_monthly_profit THEN 'Below Avg'
            ELSE 'Avg'
        END AS profit_category,
        CONCAT('Cust', rc.c_customer_id, '_', CAST(rc.d_year AS VARCHAR), '-', LPAD(CAST(rc.sales_month AS VARCHAR), 2, '0')) AS cust_month_key,
        rc.net_profit_adj / NULLIF(rc.total_quantity, 0) AS profit_per_quantity,
        CASE
            WHEN rc.avg_other_profit IS NULL THEN NULL
            WHEN rc.net_profit_adj > rc.avg_other_profit THEN 1
            WHEN rc.net_profit_adj < rc.avg_other_profit THEN -1
            ELSE 0
        END AS profit_vs_others_flag
    FROM ranked_customers rc
    WHERE rc.profit_rank <= 10
      AND (rc.c_preferred_cust_flag = 'Y' OR rc.c_preferred_cust_flag IS NULL)
      AND (rc.total_sales > 1000 OR rc.total_sales = 0)
      AND NOT (rc.returns_count > 5 AND rc.avg_net_margin < 0.1)
)
SELECT *
FROM final_result
ORDER BY d_year, sales_month, profit_rank
