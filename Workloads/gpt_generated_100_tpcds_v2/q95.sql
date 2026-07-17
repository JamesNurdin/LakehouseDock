WITH store_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        cd.cd_gender AS gender,
        ca.ca_state AS state,
        AVG(sr.sr_return_amt) AS avg_store_return_amt,
        SUM(sr.sr_return_quantity) AS total_store_return_qty
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE i.i_current_price > 50.00
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, cd.cd_gender, ca.ca_state
),
web_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        cd.cd_gender AS gender,
        ca.ca_state AS state,
        AVG(wr.wr_return_amt) AS avg_web_return_amt,
        SUM(wr.wr_return_quantity) AS total_web_return_qty
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE i.i_current_price > 50.00
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, cd.cd_gender, ca.ca_state
)
SELECT
    COALESCE(s.i_item_id, w.i_item_id) AS item_id,
    COALESCE(s.i_product_name, w.i_product_name) AS product_name,
    COALESCE(s.gender, w.gender) AS gender,
    COALESCE(s.state, w.state) AS state,
    s.avg_store_return_amt,
    w.avg_web_return_amt,
    (w.avg_web_return_amt - s.avg_store_return_amt) AS diff_return_amt,
    s.total_store_return_qty,
    w.total_web_return_qty
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.i_item_sk = w.i_item_sk
    AND s.gender = w.gender
    AND s.state = w.state
WHERE s.avg_store_return_amt IS NOT NULL
  AND w.avg_web_return_amt IS NOT NULL
  AND w.avg_web_return_amt > s.avg_store_return_amt * 1.2
ORDER BY diff_return_amt DESC
LIMIT 10
