WITH sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        i.i_category,
        i.i_item_id,
        i.i_current_price,
        s.s_store_name,
        p.p_promo_name,
        hd_sales.hd_income_band_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
),
returns AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_net_loss,
        sr.sr_reason_sk,
        hd_ret.hd_income_band_sk AS hd_ret_income_band_sk
    FROM store_returns sr
    LEFT JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
),
catalog AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_net_loss,
        cr.cr_warehouse_sk
    FROM catalog_returns cr
),
inv AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand
    FROM inventory inv
),
inc AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM income_band ib
)
SELECT
    s.s_store_name,
    i.i_category,
    ib.ib_lower_bound,
    SUM(sa.ss_net_paid) AS total_sales,
    SUM(r.sr_net_loss) AS total_returns_loss,
    SUM(ca.cr_net_loss) AS total_catalog_returns_loss,
    COUNT(DISTINCT sa.ss_ticket_number) AS num_transactions,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(sa.ss_net_paid) DESC) AS sales_rank_by_store
FROM sales sa
JOIN item i ON sa.ss_item_sk = i.i_item_sk
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN promotion p ON sa.ss_promo_sk = p.p_promo_sk
JOIN household_demographics hd_sales ON sa.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN income_band ib ON hd_sales.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN returns r ON r.sr_ticket_number = sa.ss_ticket_number
LEFT JOIN catalog ca ON ca.cr_item_sk = i.i_item_sk
LEFT JOIN warehouse w ON ca.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN reason re ON r.sr_reason_sk = re.r_reason_sk
LEFT JOIN household_demographics hd_ret ON r.sr_ticket_number = sa.ss_ticket_number AND r.sr_net_loss IS NOT NULL -- ensure alias usage
WHERE i.i_current_price > 50
  AND EXISTS (
        SELECT 1 FROM inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_quantity_on_hand > 500
    )
GROUP BY s.s_store_name, i.i_category, ib.ib_lower_bound
ORDER BY total_sales DESC
LIMIT 100
