WITH base AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_county,
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price,
        s.s_store_name,
        s.s_store_sk,
        ca_cust.ca_address_sk AS cust_address_sk,
        hd_cust.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cr.cr_return_amount,
        cr.cr_net_loss,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca_cust ON ss.ss_addr_sk = ca_cust.ca_address_sk
    JOIN household_demographics hd_cust ON ss.ss_hdemo_sk = hd_cust.hd_demo_sk
    JOIN income_band ib ON hd_cust.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN reason r_cat ON cr.cr_reason_sk = r_cat.r_reason_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_county = 'Marshall County'
      AND i.i_current_price BETWEEN 20 AND 100
      AND hd_cust.hd_vehicle_count >= 1
      AND cr.cr_return_amount > 100.00
      AND ss.ss_quantity > 2
)
SELECT DISTINCT
    b.w_warehouse_name,
    b.w_county,
    b.i_item_id,
    b.i_current_price,
    b.s_store_name,
    b.cust_address_sk,
    b.hd_vehicle_count,
    b.ib_lower_bound,
    b.ib_upper_bound,
    b.inv_quantity_on_hand,
    b.cr_return_amount,
    b.sr_return_amt,
    b.cr_net_loss,
    SUM(b.cr_return_amount + COALESCE(b.sr_return_amt, 0)) OVER (
        PARTITION BY b.w_warehouse_sk
        ORDER BY b.i_current_price DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amount,
    RANK() OVER (
        PARTITION BY b.w_warehouse_sk
        ORDER BY (b.cr_return_amount + COALESCE(b.sr_return_amt, 0)) DESC
    ) AS return_rank
FROM base b
ORDER BY b.w_warehouse_name, return_rank
LIMIT 100
