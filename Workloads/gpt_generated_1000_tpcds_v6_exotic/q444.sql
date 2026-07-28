SELECT
    i.i_brand,
    i.i_category,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
    MIN(cs.cs_sales_price) AS min_sales_price,
    MAX(cs.cs_sales_price) AS max_sales_price,
    SUM(CASE WHEN cs.cs_net_profit > 1000 THEN cs.cs_net_profit ELSE 0 END) AS high_profit_sum,
    COUNT(DISTINCT p.p_promo_name) AS distinct_promos
FROM
    item i
    JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number AND wr.wr_reason_sk = r.r_reason_sk
WHERE
    i.i_brand = 'Brand#23'
    AND p.p_discount_active = 'Y'
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450500
    AND ws.ws_sales_price > 50.00
    AND wsit.web_state = 'CA'
    AND r.r_reason_desc = 'Customer not interested'
    AND cr.cr_return_amount < 100.00
GROUP BY
    i.i_brand,
    i.i_category
ORDER BY
    total_net_paid DESC
LIMIT 100
