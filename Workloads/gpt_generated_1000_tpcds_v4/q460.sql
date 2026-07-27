/*
Goal: Analyze total net profit and sales for catalog and web orders in 2001, limited to the second shift, California call centers, active promotions, and only those web orders that have a corresponding return. The query joins all nine selected tables, applies four selective filters, uses an EXISTS sub‑query for the semi‑join, aggregates key metrics, orders by total sales, and returns the top 100 rows.
*/
SELECT
    cc.cc_name,
    p.p_promo_name,
    d_cat.d_year,
    t_cat.t_shift,
    COUNT(DISTINCT cs.cs_order_number)               AS catalog_orders,
    SUM(cs.cs_net_profit)                           AS catalog_profit,
    COUNT(DISTINCT ws.ws_order_number)              AS web_orders,
    SUM(ws.ws_net_profit)                           AS web_profit,
    SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_sales_price)                      AS avg_catalog_sale,
    AVG(ws.ws_ext_sales_price)                      AS avg_web_sale
FROM
    catalog_sales cs
    JOIN date_dim d_cat ON cs.cs_sold_date_sk = d_cat.d_date_sk
    JOIN time_dim t_cat ON cs.cs_sold_time_sk = t_cat.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON ws.ws_order_number = cs.cs_order_number
                     AND ws.ws_item_sk = cs.cs_item_sk
    JOIN date_dim d_web ON ws.ws_sold_date_sk = d_web.d_date_sk
    JOIN time_dim t_web ON ws.ws_sold_time_sk = t_web.t_time_sk
WHERE
    d_cat.d_year = 2001                                 -- filter on calendar year
    AND t_cat.t_shift = 'second'                        -- filter on time shift
    AND cc.cc_state = 'CA'                              -- filter on call‑center state
    AND p.p_discount_active = 'Y'                       -- filter on active promotions
    AND ca.ca_state = 'CA'                              -- filter on customer address state
    AND EXISTS (                                         -- semi‑join to web_returns
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_returned_date_sk = d_web.d_date_sk
          AND wr.wr_returned_time_sk = t_web.t_time_sk
    )
GROUP BY
    cc.cc_name,
    p.p_promo_name,
    d_cat.d_year,
    t_cat.t_shift
ORDER BY
    total_sales DESC
LIMIT 100
