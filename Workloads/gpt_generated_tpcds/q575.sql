WITH sr_monthly AS (
    SELECT
        dr.d_year,
        dr.d_moy,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    GROUP BY dr.d_year, dr.d_moy
),
inv_monthly AS (
    SELECT
        di.d_year,
        di.d_moy,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    JOIN date_dim di ON inv.inv_date_sk = di.d_date_sk
    GROUP BY di.d_year, di.d_moy
),
promo_monthly AS (
    SELECT
        dp.d_year,
        dp.d_moy,
        COUNT(DISTINCT p.p_promo_sk) AS promotions_started
    FROM promotion p
    JOIN date_dim dp ON p.p_start_date_sk = dp.d_date_sk
    GROUP BY dp.d_year, dp.d_moy
),
website_monthly AS (
    SELECT
        dw.d_year,
        dw.d_moy,
        COUNT(DISTINCT ws.web_site_sk) AS websites_opened
    FROM web_site ws
    JOIN date_dim dw ON ws.web_open_date_sk = dw.d_date_sk
    GROUP BY dw.d_year, dw.d_moy
)
SELECT
    sr.d_year,
    sr.d_moy,
    sr.total_net_loss,
    sr.distinct_customers,
    inv.total_quantity_on_hand,
    promo.promotions_started,
    ws.websites_opened
FROM sr_monthly sr
LEFT JOIN inv_monthly inv
    ON sr.d_year = inv.d_year AND sr.d_moy = inv.d_moy
LEFT JOIN promo_monthly promo
    ON sr.d_year = promo.d_year AND sr.d_moy = promo.d_moy
LEFT JOIN website_monthly ws
    ON sr.d_year = ws.d_year AND sr.d_moy = ws.d_moy
ORDER BY sr.d_year, sr.d_moy
