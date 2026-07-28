WITH sales_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity)   AS total_qty
    FROM store_sales ss
    GROUP BY ss.ss_item_sk, ss.ss_store_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    p.p_promo_name,
    r_store.r_reason_desc        AS store_return_reason,
    cr.cr_return_amount,
    sales_agg.total_profit,
    sales_agg.total_qty,
    ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY sales_agg.total_profit DESC) AS profit_rank,
    CASE
        WHEN cr.cr_net_loss > 0 THEN 'Loss'
        ELSE 'Gain'
    END AS return_type
FROM sales_agg
JOIN store_sales ss
    ON ss.ss_item_sk = sales_agg.ss_item_sk
   AND ss.ss_store_sk = sales_agg.ss_store_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN reason r_store
    ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
WHERE i.i_current_price > 50
  AND ib.ib_lower_bound >= 50001
  AND ca.ca_state = 'CA'
ORDER BY profit_rank, i.i_item_id
