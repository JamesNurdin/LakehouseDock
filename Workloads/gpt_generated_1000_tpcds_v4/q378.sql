WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_time_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_item_sk,
        ws.ws_ext_tax,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_net_profit,
        ws.ws_quantity
    FROM web_sales ws
    WHERE ws.ws_ext_tax > 20.0
      AND ws.ws_net_paid_inc_ship_tax > 5000
)
SELECT
    ws_site.web_market_manager,
    promo.p_promo_name,
    td.t_hour,
    td.t_sub_shift,
    reason.r_reason_desc,
    COUNT(DISTINCT sales.ws_order_number) AS orders_cnt,
    SUM(sales.ws_quantity) AS total_quantity_sold,
    SUM(sales.ws_net_paid_inc_ship_tax) AS total_sales_amount,
    SUM(CASE WHEN promo.p_discount_active = 'Y' THEN sales.ws_net_paid_inc_ship_tax * 0.9 ELSE sales.ws_net_paid_inc_ship_tax END) AS discounted_sales_amount,
    SUM(COALESCE(ret.wr_return_amt, 0)) AS total_return_amount,
    SUM(sales.ws_net_profit) - SUM(COALESCE(ret.wr_return_amt, 0)) AS net_contribution,
    AVG(sales.ws_ext_tax) AS avg_tax,
    MAX(sales.ws_net_paid_inc_ship_tax) AS max_single_payment,
    (SELECT AVG(ws_ext_tax) FROM web_sales) AS overall_avg_tax
FROM sales_data sales
JOIN time_dim td
    ON sales.ws_sold_time_sk = td.t_time_sk
JOIN web_site ws_site
    ON sales.ws_web_site_sk = ws_site.web_site_sk
JOIN promotion promo
    ON sales.ws_promo_sk = promo.p_promo_sk
LEFT JOIN web_returns ret
    ON ret.wr_item_sk = sales.ws_item_sk
   AND ret.wr_order_number = sales.ws_order_number
   AND ret.wr_returned_time_sk = td.t_time_sk
JOIN reason
    ON ret.wr_reason_sk = reason.r_reason_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND td.t_sub_shift = 'morning'
  AND ws_site.web_market_manager = 'James Harris'
  AND promo.p_discount_active = 'Y'
  AND reason.r_reason_desc IN ('Customer Not Satisfied', 'Damaged Item')
GROUP BY
    ws_site.web_market_manager,
    promo.p_promo_name,
    td.t_hour,
    td.t_sub_shift,
    reason.r_reason_desc
HAVING SUM(sales.ws_net_paid_inc_ship_tax) > 10000
ORDER BY total_sales_amount DESC
LIMIT 100
