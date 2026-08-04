WITH joined_data AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_year,
        s.s_store_name,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        cr.cr_return_amount,
        cr.cr_net_loss,
        inv.inv_quantity_on_hand,
        hd.hd_buy_potential,
        web.web_name,
        web.web_company_id
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND hd.hd_income_band_sk > 3
      AND web.web_company_id IN (1, 2)
)
SELECT
    d_date,
    d_year,
    s_store_name,
    web_name,
    hd_buy_potential,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ws_ext_sales_price) AS total_sales_price,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
    CASE WHEN SUM(cr_net_loss) > 0 THEN 'Net Loss' ELSE 'Net Gain' END AS net_status,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = jd.d_date_sk
    ) AS avg_return_amount_same_day,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(cr_net_loss) DESC) AS loss_rank
FROM joined_data jd
GROUP BY d_date, d_year, s_store_name, web_name, hd_buy_potential, jd.d_date_sk
ORDER BY loss_rank
LIMIT 100
