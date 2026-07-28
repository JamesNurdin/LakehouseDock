WITH joined AS (
    SELECT
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_quantity,
        d_sold.d_year AS year,
        i.i_item_id,
        i.i_category,
        ca_bill.ca_state AS state,
        sm.sm_type,
        ws.ws_quantity,
        ws.ws_net_paid,
        sr.sr_return_amt,
        sr.sr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_category = 'Sports'
      AND ca_bill.ca_state = 'CA'
      AND cs.cs_net_paid > 100
      AND ws.ws_quantity BETWEEN 10 AND 100
      AND sm.sm_type = 'AIR'
      AND NOT EXISTS (
          SELECT 1 FROM store_returns sr_ex
          WHERE sr_ex.sr_item_sk = i.i_item_sk
            AND sr_ex.sr_return_amt > 2000
      )
),
agg AS (
    SELECT
        year,
        i_item_id,
        i_category,
        state,
        SUM(cs_net_profit)            AS sum_net_profit,
        SUM(ws_net_paid)              AS sum_ws_net_paid,
        SUM(sr_return_amt)            AS sum_store_return_amt,
        SUM(wr_return_amt)            AS sum_web_return_amt,
        COUNT(*)                      AS txn_count
    FROM joined
    GROUP BY year, i_item_id, i_category, state
)
SELECT
    year,
    i_item_id,
    i_category,
    state,
    sum_net_profit,
    sum_ws_net_paid,
    sum_store_return_amt,
    sum_web_return_amt,
    txn_count,
    RANK() OVER (PARTITION BY year ORDER BY sum_net_profit DESC) AS profit_rank,
    SUM(sum_net_profit) OVER (PARTITION BY year)               AS year_total_profit
FROM agg
WHERE sum_net_profit > 500
ORDER BY year DESC, profit_rank
LIMIT 100
