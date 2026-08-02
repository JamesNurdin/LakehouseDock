WITH base AS (
    SELECT
        d.d_year,
        ws.ws_ext_sales_price,
        cr.cr_net_loss,
        CASE
            WHEN cr.cr_net_loss > 500 THEN 'HighLoss'
            WHEN cr.cr_net_loss > 100 THEN 'MediumLoss'
            ELSE 'LowLoss'
        END AS loss_category,
        ws_site.web_county
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd_returning.hd_demo_sk
    CROSS JOIN LATERAL (
        SELECT web_county
        FROM web_site w
        WHERE w.web_open_date_sk = d.d_date_sk
          AND w.web_site_sk = ws.ws_web_site_sk
    ) AS ws_site
    CROSS JOIN LATERAL (
        SELECT ib_lower_bound, ib_upper_bound
        FROM income_band ib
        WHERE ib.ib_income_band_sk = hd_refunded.hd_income_band_sk
    ) AS ib_refunded
    WHERE d.d_year = 2002
      AND hd_refunded.hd_vehicle_count >= 2
      AND ib_refunded.ib_lower_bound > 20000
      AND ws_site.web_county = 'Richland County'
      AND ws.ws_ext_tax > 20.00
      AND cr.cr_item_sk IN (
          SELECT ws_item_sk
          FROM web_sales
          WHERE ws_quantity > 5
      )
),
aggregated AS (
    SELECT
        d_year,
        web_county,
        loss_category,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(*) AS transaction_count
    FROM base
    GROUP BY ROLLUP (d_year, web_county, loss_category)
)
SELECT
    d_year,
    web_county,
    loss_category,
    total_net_loss,
    total_sales,
    transaction_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY d_year, web_county, loss_category
LIMIT 100
