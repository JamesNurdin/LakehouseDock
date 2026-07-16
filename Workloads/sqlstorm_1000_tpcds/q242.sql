WITH sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        d.d_year,
        cs.cs_item_sk AS item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit AS profit,
        c.c_customer_id AS customer_id,
        cc.cc_name AS channel_detail,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
),
sales_store AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        d.d_year,
        ss.ss_item_sk AS item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS profit,
        c.c_customer_id AS customer_id,
        st.s_store_name AS channel_detail,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store st ON ss.ss_store_sk = st.s_store_sk
),
sales_web AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        d.d_year,
        ws.ws_item_sk AS item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS profit,
        c.c_customer_id AS customer_id,
        wp.wp_url AS channel_detail,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
all_sales AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM sales_store
    UNION ALL
    SELECT * FROM sales_web
),
returns AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        d.d_year,
        cr.cr_item_sk AS item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        cr.cr_return_quantity AS quantity,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        'catalog' AS channel
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        sr.sr_returned_date_sk,
        d.d_year,
        sr.sr_item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        'store'
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        d.d_year,
        wr.wr_item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        'web'
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
aggregated_sales AS (
    SELECT
        d_year,
        i_category,
        i_class,
        i_brand,
        channel,
        COUNT(DISTINCT customer_id) AS unique_customers,
        COUNT(*) AS total_transactions,
        SUM(quantity) AS total_quantity,
        SUM(sales_amount) AS total_sales_amount,
        SUM(profit) AS total_profit
    FROM all_sales
    GROUP BY d_year, i_category, i_class, i_brand, channel
),
aggregated_returns AS (
    SELECT
        d_year,
        i_category,
        i_class,
        i_brand,
        channel,
        SUM(quantity) AS total_return_quantity,
        SUM(return_amount) AS total_return_amount,
        SUM(net_loss) AS total_return_loss
    FROM returns
    GROUP BY d_year, i_category, i_class, i_brand, channel
)
SELECT
    s.d_year,
    s.i_category,
    s.i_class,
    s.i_brand,
    s.channel,
    s.unique_customers,
    s.total_transactions,
    s.total_quantity,
    s.total_sales_amount,
    s.total_profit,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    (s.total_sales_amount - COALESCE(r.total_return_amount, 0)) AS net_sales_amount,
    CASE WHEN s.total_sales_amount > 0 THEN (COALESCE(r.total_return_amount, 0) / s.total_sales_amount) ELSE 0 END AS return_rate
FROM aggregated_sales s
LEFT JOIN aggregated_returns r
    ON s.d_year = r.d_year
    AND s.i_category = r.i_category
    AND s.i_class = r.i_class
    AND s.i_brand = r.i_brand
    AND s.channel = r.channel
WHERE s.total_sales_amount > 50000
ORDER BY net_sales_amount DESC
LIMIT 200
