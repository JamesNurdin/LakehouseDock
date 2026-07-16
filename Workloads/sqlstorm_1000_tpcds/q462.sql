WITH daily_sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        'catalog' AS sales_channel,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_call_center_sk AS call_center_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        'store' AS sales_channel,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        NULL AS call_center_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        'web' AS sales_channel,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        NULL AS call_center_sk
    FROM web_sales ws
),
customer_first_purchase AS (
    SELECT
        ds.customer_sk,
        MIN(d.d_date) AS first_purchase_date
    FROM daily_sales ds
    JOIN date_dim d ON ds.date_sk = d.d_date_sk
    GROUP BY ds.customer_sk
),
ranked_customers AS (
    SELECT
        ds.date_sk,
        d.d_date,
        d.d_year,
        ds.sales_channel,
        ds.customer_sk,
        c.c_first_name,
        c.c_last_name,
        ds.item_sk,
        i.i_product_name AS product_name,
        ds.quantity,
        ds.net_paid,
        ds.net_profit,
        cc.cc_name,
        ROW_NUMBER() OVER (PARTITION BY ds.sales_channel, d.d_year ORDER BY ds.net_profit DESC) AS profit_rank,
        COALESCE(cfp.first_purchase_date, DATE '1900-01-01') AS first_purchase_date
    FROM daily_sales ds
    LEFT JOIN date_dim d ON ds.date_sk = d.d_date_sk
    LEFT JOIN customer c ON ds.customer_sk = c.c_customer_sk
    LEFT JOIN item i ON ds.item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON ds.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN customer_first_purchase cfp ON ds.customer_sk = cfp.customer_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
),
item_returns AS (
    SELECT
        i.i_item_sk,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_catalog_returns,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_store_returns,
        COALESCE(SUM(wr.wr_return_quantity), 0) AS total_web_returns
    FROM item i
    LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
    LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
    GROUP BY i.i_item_sk
),
final AS (
    SELECT
        rc.d_date,
        rc.sales_channel,
        rc.profit_rank,
        CONCAT(rc.c_first_name, ' ', rc.c_last_name) AS customer_name,
        rc.product_name,
        rc.quantity,
        rc.net_paid,
        rc.net_profit,
        rc.cc_name,
        ir.total_catalog_returns,
        ir.total_store_returns,
        ir.total_web_returns,
        CASE
            WHEN rc.first_purchase_date > DATE '2000-01-01' THEN 'New Customer'
            ELSE 'Existing Customer'
        END AS customer_segment,
        COALESCE(rc.net_profit / NULLIF(rc.quantity, 0), 0) AS profit_per_item,
        (
            SELECT SUM(ds_sub.net_profit)
            FROM daily_sales ds_sub
            WHERE ds_sub.customer_sk = rc.customer_sk
        ) AS total_customer_net_profit
    FROM ranked_customers rc
    LEFT JOIN item_returns ir ON rc.item_sk = ir.i_item_sk
    WHERE rc.profit_rank <= 10
)

SELECT *
FROM final
ORDER BY d_date DESC, sales_channel, profit_rank
