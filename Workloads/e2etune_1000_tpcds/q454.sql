WITH brand_state_returns AS (
    SELECT
        i.i_brand AS brand,
        ca_ret.ca_state AS state,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        COUNT(*) AS return_cnt,
        SUM(CASE WHEN ca_ret.ca_state = ca_ref.ca_state THEN 1 ELSE 0 END) AS same_state_returns
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    WHERE i.i_category = 'Electronics'
      AND ca_ret.ca_country = 'United States'
      AND ca_ret.ca_location_type = 'condo'
      AND wr.wr_return_amt_inc_tax > 100
    GROUP BY i.i_brand, ca_ret.ca_state
)
SELECT
    brand,
    state,
    total_net_loss,
    total_return_amount,
    avg_return_qty,
    return_cnt,
    same_state_returns,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM brand_state_returns
ORDER BY total_net_loss DESC
LIMIT 50
