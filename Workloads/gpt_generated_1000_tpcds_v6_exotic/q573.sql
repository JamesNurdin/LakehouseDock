/*
Goal: Identify the items with the highest total return amount by combining catalog returns, store returns, and web sales, while also showing total catalog sales and categorising the return magnitude.
*/
WITH catalog_sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        SUM(cs.cs_net_paid)        AS total_catalog_net_paid,
        SUM(cs.cs_quantity)        AS total_catalog_qty
    FROM catalog_sales cs
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY cs.cs_item_sk, cs.cs_order_number
)
SELECT
    i.i_item_id,
    i.i_product_name,
    r.r_reason_desc,
    SUM(cr.cr_return_amount)          AS total_return_amount,
    SUM(sr.sr_return_amt)             AS total_store_return_amt,
    SUM(ws.ws_net_paid)               AS total_web_net_paid,
    SUM(sa.total_catalog_net_paid)    AS total_catalog_net_paid,
    CASE
        WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High Return'
        ELSE 'Normal Return'
    END                               AS return_category
FROM catalog_sales_agg sa
JOIN catalog_returns cr        ON cr.cr_order_number = sa.cs_order_number
JOIN item i                     ON cr.cr_item_sk = i.i_item_sk
JOIN reason r                   ON cr.cr_reason_sk = r.r_reason_sk
JOIN time_dim t_cr              ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN customer_demographics cd_ref   ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN household_demographics hd_ref   ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN customer_address ca_ref        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN store_returns sr          ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim t_sr             ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN customer_demographics cd_sr   ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr   ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr        ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN web_sales ws               ON ws.ws_item_sk = i.i_item_sk
JOIN web_site ws_site           ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN promotion p_ws            ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN promotion p_item          ON p_item.p_item_sk = i.i_item_sk
GROUP BY
    i.i_item_id,
    i.i_product_name,
    r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
