WITH cr AS (
  SELECT
    cr.cr_item_sk AS item_sk,
    cr.cr_refunded_cdemo_sk AS demo_sk,
    cr.cr_refunded_addr_sk AS addr_sk,
    cr.cr_net_loss AS net_loss,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    i.i_current_price,
    cd.cd_credit_rating,
    cd.cd_dep_employed_count,
    ca.ca_state,
    ca.ca_county,
    'catalog' AS source
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE i.i_current_price > 50
    AND cd.cd_credit_rating IN ('Good', 'Low Risk')
    AND ca.ca_state = 'CA'
    AND cr.cr_return_quantity > 0
),
wr AS (
  SELECT
    wr.wr_item_sk AS item_sk,
    wr.wr_refunded_cdemo_sk AS demo_sk,
    wr.wr_refunded_addr_sk AS addr_sk,
    wr.wr_net_loss AS net_loss,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    i.i_current_price,
    cd.cd_credit_rating,
    cd.cd_dep_employed_count,
    ca.ca_state,
    ca.ca_county,
    'web' AS source
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    AND wp.wp_customer_sk = c.c_customer_sk
  WHERE i.i_current_price > 50
    AND cd.cd_credit_rating IN ('Good', 'Low Risk')
    AND ca.ca_state = 'CA'
    AND wr.wr_return_quantity > 0
    AND wr.wr_account_credit > 100
),
combined AS (
  SELECT * FROM cr
  UNION ALL
  SELECT * FROM wr
),
agg AS (
  SELECT
    i_item_id,
    i_brand,
    i_category,
    cd_credit_rating,
    ca_state,
    SUM(CASE WHEN source = 'catalog' THEN net_loss ELSE 0 END) AS total_catalog_net_loss,
    SUM(CASE WHEN source = 'web' THEN net_loss ELSE 0 END) AS total_web_net_loss,
    SUM(net_loss) AS total_net_loss,
    COUNT(*) AS total_return_count
  FROM combined
  GROUP BY
    i_item_id,
    i_brand,
    i_category,
    cd_credit_rating,
    ca_state
)
SELECT
  i_item_id,
  i_brand,
  i_category,
  cd_credit_rating,
  ca_state,
  total_catalog_net_loss,
  total_web_net_loss,
  total_net_loss,
  total_return_count,
  RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
  AVG(total_net_loss) OVER (ORDER BY total_net_loss DESC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_net_loss
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
