WITH returns_agg AS (
    SELECT
        cr_order_number,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        MAX(cr_returned_time_sk) AS max_return_time_sk
    FROM catalog_returns
    WHERE cr_fee > 30
      AND cr_refunded_cash > 0
    GROUP BY cr_order_number
)
SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    sm.sm_code,
    td_sold.t_hour AS sold_hour,
    td_return.t_hour AS return_hour,
    cs.cs_quantity,
    cs.cs_net_paid,
    ra.total_return_amount,
    ra.total_net_loss,
    CASE
        WHEN ra.total_net_loss > 100 THEN 'HIGH_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_category,
    RANK() OVER (PARTITION BY sm.sm_code ORDER BY cs.cs_net_paid DESC) AS sales_rank_by_shipmode,
    ROW_NUMBER() OVER (PARTITION BY ca_bill.ca_state ORDER BY cs.cs_net_paid DESC) AS row_num_state
FROM catalog_sales cs
JOIN returns_agg ra
    ON cs.cs_order_number = ra.cr_order_number
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td_sold
    ON cs.cs_sold_time_sk = td_sold.t_time_sk
JOIN time_dim td_return
    ON ra.max_return_time_sk = td_return.t_time_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
WHERE sm.sm_code IN ('AIR', 'SEA')
  AND td_sold.t_hour BETWEEN 8 AND 18
  AND cs.cs_quantity BETWEEN 1 AND 10
  AND ca_bill.ca_state = 'CA'
  AND ca_ship.ca_state <> 'NY'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = cs.cs_order_number
          AND cr.cr_fee > 50
    )
ORDER BY sm.sm_code, sales_rank_by_shipmode
