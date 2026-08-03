WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_warehouse_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_order_number,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_refunded_addr_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 20
      AND cr.cr_return_quantity >= 1
)
SELECT
    w.w_warehouse_name,
    wp.wp_type,
    ca.ca_state,
    hd.hd_buy_potential,
    COUNT(DISTINCT fr.cr_order_number) AS num_returns,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    ROW_NUMBER() OVER (ORDER BY SUM(fr.cr_return_amount) DESC) AS rn
FROM filtered_returns fr
JOIN warehouse w
  ON fr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca
  ON fr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON fr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN customer_demographics cd
  ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE w.w_state = 'CA'
  AND ca.ca_state = 'CA'
  AND hd.hd_buy_potential = '1001-5000'
  AND wp.wp_rec_start_date = DATE '2000-09-03'
  AND ws.ws_list_price > 50
  AND fr.cr_return_amount > (SELECT AVG(cr_return_amount) FROM catalog_returns)
GROUP BY
    w.w_warehouse_name,
    wp.wp_type,
    ca.ca_state,
    hd.hd_buy_potential
ORDER BY total_return_amount DESC
LIMIT 100
