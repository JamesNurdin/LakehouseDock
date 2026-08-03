WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        ws.ws_item_sk AS ws_item_sk,
        ws.ws_bill_customer_sk AS ws_bill_customer_sk,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_ext_discount_amt AS ws_ext_discount_amt,
        ws.ws_web_page_sk,
        sr.sr_item_sk AS sr_item_sk,
        sr.sr_customer_sk AS sr_customer_sk,
        sr.sr_addr_sk AS sr_addr_sk,
        sr.sr_returned_date_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_return_amt_inc_tax,
        s.s_state,
        r.r_reason_desc,
        i.i_category,
        dd.d_year,
        CASE WHEN cs.cs_quantity > 5 THEN 'High Qty' ELSE 'Low Qty' END AS qty_category
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_returned_date_sk = dd.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE dd.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND cs.cs_ext_sales_price > 3000
      AND ws.ws_net_paid > 5000
      AND sr.sr_return_amt_inc_tax BETWEEN 100 AND 5000
)
SELECT
    d_year,
    i_category,
    s_state,
    r_reason_desc,
    qty_category,
    SUM(cs_net_paid) AS total_catalog_net_paid,
    AVG(ws_net_paid) AS avg_web_net_paid,
    COUNT(DISTINCT cs_sold_date_sk) AS distinct_sales_days,
    SUM(sr_return_amt_inc_tax) AS total_return_amount,
    MAX(cs_ext_sales_price) AS max_catalog_sales_price,
    MIN(ws_ext_discount_amt) AS min_web_discount
FROM base
GROUP BY
    d_year,
    i_category,
    s_state,
    r_reason_desc,
    qty_category
ORDER BY total_catalog_net_paid DESC
LIMIT 100
