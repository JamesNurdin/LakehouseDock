WITH sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        d.d_year AS year,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(sr.sr_return_amt) AS store_returns,
        SUM(cr.cr_return_amount) AS catalog_returns,
        SUM(wr.wr_return_amt) AS web_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txns,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_txns,
        COUNT(DISTINCT ws.ws_order_number) AS web_txns
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
           AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
           AND cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
           AND cr.cr_item_sk = i.i_item_sk
           AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
           AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
           AND wr.wr_item_sk = i.i_item_sk
           AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
           AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_site wsite
        ON wsite.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2001 AND 2003
        AND t.t_am_pm = 'PM'
        AND i.i_brand_id IN (101, 202, 303)
        AND p.p_discount_active = 'Y'
        AND ca.ca_state IN ('CA', 'TX', 'NY')
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY i.i_item_id, i.i_product_name, d.d_year
)
SELECT
    item_id,
    product_name,
    year,
    store_sales,
    catalog_sales,
    web_sales,
    (store_sales + catalog_sales + web_sales) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY (store_sales + catalog_sales + web_sales) DESC) AS sales_rank
FROM sales_agg
WHERE (store_sales + catalog_sales + web_sales) > 10000
ORDER BY year, sales_rank
LIMIT 100
