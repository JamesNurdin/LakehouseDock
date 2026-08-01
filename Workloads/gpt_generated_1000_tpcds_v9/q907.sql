WITH store_agg AS (
    SELECT
        sr_addr_sk,
        COUNT(*) AS store_ret_cnt,
        SUM(sr_net_loss) AS store_total_net_loss,
        AVG(sr_return_tax) AS store_avg_return_tax,
        SUM(sr_return_quantity) AS store_total_quantity
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_tax >= 0
      AND sr_return_amt > 0
      AND sr_fee >= 0
      AND sr_reversed_charge >= 0
      AND sr_store_credit >= 0
    GROUP BY sr_addr_sk
),
web_agg AS (
    SELECT
        wr_refunded_addr_sk,
        COUNT(*) AS web_ret_cnt,
        SUM(wr_net_loss) AS web_total_net_loss,
        SUM(wr_return_ship_cost) AS web_total_ship_cost,
        AVG(wr_return_tax) AS web_avg_return_tax,
        SUM(wr_refunded_cash) AS web_total_refunded_cash
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_return_ship_cost > 50
      AND wr_refunded_cash >= 0
      AND wr_return_tax >= 0
      AND wr_return_amt > 0
    GROUP BY wr_refunded_addr_sk
)
SELECT
    ca.ca_address_id,
    ca.ca_suite_number,
    ca.ca_state,
    ca.ca_gmt_offset,
    store_agg.store_ret_cnt,
    store_agg.store_total_net_loss,
    store_agg.store_avg_return_tax,
    wa.web_ret_cnt,
    wa.web_total_net_loss,
    (store_agg.store_total_net_loss + wa.web_total_net_loss) AS combined_net_loss,
    RANK() OVER (ORDER BY (store_agg.store_total_net_loss + wa.web_total_net_loss) DESC) AS net_loss_rank
FROM store_agg
JOIN customer_address ca
    ON store_agg.sr_addr_sk = ca.ca_address_sk
JOIN web_agg wa
    ON wa.wr_refunded_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'CA'
  AND ca.ca_gmt_offset BETWEEN -5.00 AND 5.00
  AND ca.ca_suite_number LIKE 'Suite %'
  AND store_agg.store_total_net_loss > 0
  AND wa.web_total_net_loss > 0
  AND wa.web_ret_cnt > 0
ORDER BY combined_net_loss DESC
LIMIT 100
