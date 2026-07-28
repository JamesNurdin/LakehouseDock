WITH
    /* Base catalog sales */
    cs AS (
        SELECT
            cs_sold_date_sk,
            cs_sold_time_sk,
            cs_call_center_sk,
            cs_promo_sk,
            cs_order_number,
            cs_ext_sales_price,
            cs_net_profit,
            cs_bill_customer_sk,
            cs_bill_cdemo_sk,
            cs_item_sk
        FROM catalog_sales
    ),
    /* Base catalog returns */
    cr AS (
        SELECT
            cr_order_number,
            cr_item_sk,
            cr_returned_date_sk,
            cr_returned_time_sk,
            cr_return_amount,
            cr_refunded_customer_sk,
            cr_refunded_cdemo_sk,
            cr_returning_customer_sk,
            cr_returning_cdemo_sk,
            cr_call_center_sk
        FROM catalog_returns
    ),
    /* Base web sales */
    ws AS (
        SELECT
            ws_sold_date_sk,
            ws_sold_time_sk,
            ws_web_page_sk,
            ws_promo_sk,
            ws_ext_sales_price,
            ws_net_profit,
            ws_bill_customer_sk,
            ws_bill_cdemo_sk
        FROM web_sales
    )
SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    cc.cc_name,
    p.p_promo_name,
    SUM(cs.cs_ext_sales_price)                      AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price)                      AS total_web_sales,
    SUM(cr.cr_return_amount)                       AS total_returns,
    SUM(inv.inv_quantity_on_hand)                  AS total_inventory_on_date,
    (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_return_amount)) AS net_contribution,
    RANK() OVER (PARTITION BY d_sales.d_year ORDER BY (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_return_amount)) DESC) AS profit_rank
FROM cs
JOIN date_dim d_sales          ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales          ON cs.cs_sold_time_sk = t_sales.t_time_sk
JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c_bill           ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk

JOIN cr                        ON cr.cr_order_number = cs.cs_order_number
                               AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d_return         ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return         ON cr.cr_returned_time_sk = t_return.t_time_sk
JOIN customer c_refund        ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN customer c_returning     ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN call_center cc_return    ON cr.cr_call_center_sk = cc_return.cc_call_center_sk

JOIN inventory inv             ON inv.inv_date_sk = d_sales.d_date_sk

JOIN ws                        ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_web            ON ws.ws_sold_time_sk = t_web.t_time_sk
JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN promotion p_web           ON ws.ws_promo_sk = p_web.p_promo_sk
WHERE d_sales.d_year = 2001
  AND cc.cc_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND t_sales.t_meal_time = 'dinner'
  AND cs.cs_ext_sales_price > 500
  AND inv.inv_quantity_on_hand BETWEEN 100 AND 1000
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    cc.cc_name,
    p.p_promo_name
ORDER BY net_contribution DESC
LIMIT 100
