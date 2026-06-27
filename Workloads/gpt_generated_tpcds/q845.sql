WITH unified_sales AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_order_number AS order_number,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_quantity AS quantity,
        cs.cs_sales_price AS sales_price
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        ss.ss_sales_price
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_quantity,
        ws.ws_sales_price
    FROM web_sales ws
)
SELECT
    i.i_category,
    d.d_year,
    d.d_moy,
    SUM(us.net_profit) AS total_net_profit,
    SUM(us.discount_amt) AS total_discount,
    SUM(us.quantity) AS total_quantity,
    AVG(us.sales_price) AS avg_sales_price,
    COUNT(DISTINCT us.order_number) AS distinct_orders
FROM unified_sales us
JOIN date_dim d
    ON us.sold_date_sk = d.d_date_sk
JOIN item i
    ON us.item_sk = i.i_item_sk
LEFT JOIN promotion p
    ON us.promo_sk = p.p_promo_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND (p.p_promo_sk IS NULL OR (p.p_start_date_sk <= us.sold_date_sk AND p.p_end_date_sk >= us.sold_date_sk))
GROUP BY
    i.i_category,
    d.d_year,
    d.d_moy
ORDER BY total_net_profit DESC
LIMIT 100
