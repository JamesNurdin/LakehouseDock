WITH returns_agg AS (
    SELECT
        cr_returning_addr_sk AS addr_sk,
        COUNT(*) AS cnt_returns,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(cr_net_loss) AS sum_net_loss
    FROM catalog_returns
    WHERE cr_return_amount > 10
      AND cr_return_quantity >= 1
      AND cr_ship_mode_sk IN (2, 4, 5, 10)
      AND cr_returning_hdemo_sk BETWEEN 3000 AND 7000
    GROUP BY cr_returning_addr_sk
),
sales_agg AS (
    SELECT
        ws_bill_addr_sk AS addr_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_qty
    FROM web_sales
    WHERE ws_list_price BETWEEN 50 AND 200
      AND ws_ship_customer_sk > 1000000
    GROUP BY ws_bill_addr_sk
)
SELECT
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    r.cnt_returns,
    r.sum_return_amount,
    s.total_sales,
    s.total_qty,
    RANK() OVER (ORDER BY r.sum_return_amount DESC) AS return_amount_rank,
    CASE WHEN r.sum_net_loss > 1000 THEN 'HIGH_LOSS' ELSE 'LOW_LOSS' END AS loss_category
FROM returns_agg r
JOIN customer_address ca
    ON r.addr_sk = ca.ca_address_sk
JOIN sales_agg s
    ON s.addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'CA'
  AND ca.ca_city LIKE 'San%'
  AND ca.ca_zip LIKE '94%'
ORDER BY r.sum_return_amount DESC
LIMIT 100
