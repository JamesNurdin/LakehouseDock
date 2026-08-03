WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
)
SELECT
    s.s_store_name,
    i.i_item_id,
    i.i_brand,
    p.p_promo_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    cr.cr_return_amount,
    sr.sr_return_amt,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
    RANK() OVER (PARTITION BY s.s_store_name ORDER BY ss.ss_net_profit DESC) AS profit_rank,
    SUM(ss.ss_quantity) OVER (
        PARTITION BY i.i_item_id
        ORDER BY ss.ss_sold_date_sk
        ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
    ) AS qty_last_30_days
FROM sales_base ss
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
FULL OUTER JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
FULL OUTER JOIN catalog_returns cr
    ON ss.ss_item_sk = cr.cr_item_sk
LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
WHERE s.s_state = 'CA'
  AND i.i_current_price > 20
  AND p.p_discount_active = 'Y'
  AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450500
  AND ib.ib_upper_bound <= 50000
  AND EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_desc = 'Damaged'
          AND r2.r_reason_sk = sr.sr_reason_sk
    )
ORDER BY profit_rank ASC, ss.ss_net_profit DESC
LIMIT 100
