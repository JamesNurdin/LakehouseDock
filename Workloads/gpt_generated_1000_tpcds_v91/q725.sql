WITH store_ret_agg AS (
    SELECT
        dd.d_year AS return_year,
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM store_returns sr
    CROSS JOIN LATERAL (
        SELECT d_year
        FROM date_dim
        WHERE d_date_sk = sr.sr_returned_date_sk
    ) AS dd
    CROSS JOIN UNNEST (ARRAY[sr.sr_return_amt, sr.sr_return_tax, sr.sr_fee]) AS u(component)
    WHERE u.component > 0
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_returning_customer_sk = sr.sr_customer_sk
            AND cr.cr_return_amount > 50
      )
    GROUP BY dd.d_year, sr.sr_customer_sk
),

catalog_ret_agg AS (
    SELECT
        dd.d_year AS return_year,
        cr.cr_returning_customer_sk AS customer_sk,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    CROSS JOIN LATERAL (
        SELECT d_year
        FROM date_dim
        WHERE d_date_sk = cr.cr_returned_date_sk
    ) AS dd
    CROSS JOIN UNNEST (ARRAY[cr.cr_return_amount, cr.cr_return_tax, cr.cr_fee]) AS u(component)
    WHERE u.component > 0
      AND cr.cr_ship_mode_sk IN (
          SELECT sm_ship_mode_sk
          FROM ship_mode
          WHERE sm_type = 'AIR'
      )
    GROUP BY dd.d_year, cr.cr_returning_customer_sk
),

combined_agg AS (
    SELECT
        return_year,
        customer_sk,
        total_net_loss,
        return_count
    FROM store_ret_agg
    UNION ALL
    SELECT
        return_year,
        customer_sk,
        total_net_loss,
        return_count
    FROM catalog_ret_agg
)

SELECT
    return_year,
    customer_sk,
    total_net_loss,
    return_count,
    ROW_NUMBER() OVER (PARTITION BY return_year ORDER BY total_net_loss DESC) AS rank
FROM combined_agg
ORDER BY return_year DESC, total_net_loss DESC
LIMIT 100
