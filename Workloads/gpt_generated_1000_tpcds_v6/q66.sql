/* Goal: Analyze total profit and loss by customer state and promotion across both catalog and web channels, including return impacts, and rank states by profit. */
WITH catalog_data AS (
    SELECT
        ca_bill.ca_state AS state,
        p.p_promo_name AS promo_name,
        cs.cs_order_number AS order_number,
        cs.cs_net_profit AS net_profit,
        COALESCE(cr.cr_net_loss, 0) AS net_loss
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN customer_address ca_refund
      ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    LEFT JOIN customer_address ca_returning
      ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
),
web_data AS (
    SELECT
        ca_ws_bill.ca_state AS state,
        p2.p_promo_name AS promo_name,
        ws.ws_order_number AS order_number,
        ws.ws_net_profit AS net_profit,
        COALESCE(wr.wr_net_loss, 0) AS net_loss
    FROM web_sales ws
    JOIN warehouse w2
      ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    JOIN promotion p2
      ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN customer_address ca_ws_bill
      ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN customer_address ca_wr_refund
      ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
    LEFT JOIN customer_address ca_wr_returning
      ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
)
SELECT
    state,
    promo_name,
    SUM(net_profit) AS total_profit,
    SUM(net_loss) AS total_loss,
    COUNT(DISTINCT order_number) AS order_cnt,
    RANK() OVER (ORDER BY SUM(net_profit) DESC) AS profit_rank
FROM (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM web_data
) combined
GROUP BY
    state,
    promo_name
ORDER BY
    total_profit DESC
