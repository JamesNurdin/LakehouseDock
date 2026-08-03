WITH joined AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        d.d_year,
        cd.cd_gender,
        p.p_promo_name,
        p.p_channel_demo,
        p.p_channel_event,
        p.p_channel_details
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
      ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002                 -- predicate 1
      AND cd.cd_gender IN ('M', 'F')                     -- predicate 2
      AND p.p_channel_demo = 'N'                         -- predicate 3
      AND p.p_channel_event = 'N'                        -- predicate 4
      AND cr.cr_return_amount > 20.00                    -- predicate 5
      AND p.p_promo_name LIKE '%Sale%'                   -- predicate 6
),
agg AS (
    SELECT
        d_year,
        cd_gender,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        ARRAY_AGG(p_channel_details) AS details_arr
    FROM joined
    GROUP BY ROLLUP (d_year, cd_gender)
)
SELECT
    d_year,
    cd_gender,
    total_return_amount,
    total_net_loss,
    detail
FROM agg
CROSS JOIN UNNEST(details_arr) AS t(detail)
WHERE total_return_amount > (SELECT AVG(cr_return_amount) FROM catalog_returns)
  AND EXISTS (SELECT 1 FROM promotion p2 WHERE p2.p_channel_demo = 'N')
UNION
SELECT
    d_year,
    cd_gender,
    total_return_amount,
    total_net_loss,
    detail
FROM agg
CROSS JOIN UNNEST(details_arr) AS t(detail)
WHERE total_return_amount <= (SELECT AVG(cr_return_amount) FROM catalog_returns)
ORDER BY d_year DESC NULLS LAST, cd_gender
LIMIT 100
