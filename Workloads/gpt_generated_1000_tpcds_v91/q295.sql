WITH warehouse_gender_returns AS (
  SELECT
    warehouse.w_warehouse_id AS warehouse_id,
    warehouse.w_city AS warehouse_city,
    customer_demographics.cd_gender AS gender,
    SUM(catalog_returns.cr_net_loss) AS catalog_net_loss,
    SUM(web_returns.wr_net_loss) AS web_net_loss,
    COUNT(DISTINCT catalog_returns.cr_order_number) AS catalog_return_cnt,
    COUNT(DISTINCT web_returns.wr_order_number) AS web_return_cnt,
    SUM(web_sales.ws_net_profit) AS net_profit
  FROM catalog_returns
  JOIN customer
    ON catalog_returns.cr_refunded_customer_sk = customer.c_customer_sk
  JOIN customer_address
    ON catalog_returns.cr_refunded_addr_sk = customer_address.ca_address_sk
  JOIN customer_demographics
    ON catalog_returns.cr_refunded_cdemo_sk = customer_demographics.cd_demo_sk
  JOIN warehouse
    ON catalog_returns.cr_warehouse_sk = warehouse.w_warehouse_sk
  JOIN web_sales
    ON web_sales.ws_warehouse_sk = warehouse.w_warehouse_sk
  JOIN web_returns
    ON web_returns.wr_order_number = web_sales.ws_order_number
  JOIN web_page
    ON web_returns.wr_web_page_sk = web_page.wp_web_page_sk
  WHERE
    warehouse.w_country = 'United States'
    AND customer_demographics.cd_purchase_estimate > 3000
    AND web_returns.wr_return_ship_cost > 20
    AND web_page.wp_type = 'product'
  GROUP BY
    warehouse.w_warehouse_id,
    warehouse.w_city,
    customer_demographics.cd_gender
),
avg_loss_by_warehouse AS (
  SELECT
    warehouse_id,
    AVG(catalog_net_loss + web_net_loss) AS avg_total_net_loss
  FROM warehouse_gender_returns
  GROUP BY warehouse_id
)
SELECT
  wg.warehouse_id,
  wg.warehouse_city,
  wg.gender,
  wg.catalog_net_loss,
  wg.web_net_loss,
  (wg.catalog_net_loss + wg.web_net_loss) AS total_net_loss,
  CASE
    WHEN (wg.catalog_net_loss + wg.web_net_loss) > 1000 THEN 'High'
    ELSE 'Low'
  END AS loss_category,
  al.avg_total_net_loss,
  LAG((wg.catalog_net_loss + wg.web_net_loss))
    OVER (PARTITION BY wg.warehouse_id ORDER BY (wg.catalog_net_loss + wg.web_net_loss) DESC) AS lag_total_net_loss
FROM warehouse_gender_returns wg
JOIN avg_loss_by_warehouse al
  ON wg.warehouse_id = al.warehouse_id
ORDER BY total_net_loss DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
