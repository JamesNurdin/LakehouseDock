WITH per_return AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_returned_time_sk,
    cr.cr_item_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cd_ret.cd_gender AS returning_gender,
    cd_ref.cd_gender AS refunded_gender,
    d_ret.d_year,
    t.t_hour,
    s.s_store_id,
    ws.web_site_id AS ws_open_id,
    wp.wp_web_page_id AS wp_creation_id
  FROM catalog_returns cr
  JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
  JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
  JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
  JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
  WHERE d_ret.d_year = 2001
    AND t.t_hour BETWEEN 8 AND 20
    AND cr.cr_return_amount > 50
    AND s.s_state = 'CA'
),

agg_by_store_ws AS (
  SELECT
    s_store_id,
    ws_open_id,
    returning_gender,
    SUM(cr_net_loss) AS total_net_loss,
    COUNT(*) AS returns_cnt,
    MAX(cr_return_quantity) AS max_return_quantity,
    CASE
      WHEN SUM(cr_return_quantity) > 10 THEN 'HighVolume'
      ELSE 'LowVolume'
    END AS volume_category
  FROM per_return
  GROUP BY s_store_id, ws_open_id, returning_gender
)

SELECT
  a.s_store_id,
  a.ws_open_id,
  a.returning_gender,
  a.total_net_loss,
  a.returns_cnt,
  a.volume_category,
  g.avg_return_amount_for_gender,
  o.avg_total_net_loss
FROM agg_by_store_ws a
CROSS JOIN LATERAL (
  SELECT AVG(cr_l.cr_return_amount) AS avg_return_amount_for_gender
  FROM catalog_returns cr_l
  JOIN customer_demographics cd_l
    ON cr_l.cr_returning_cdemo_sk = cd_l.cd_demo_sk
  WHERE cd_l.cd_gender = a.returning_gender
) AS g
CROSS JOIN LATERAL (
  SELECT AVG(total_net_loss) AS avg_total_net_loss
  FROM agg_by_store_ws
) AS o
WHERE a.volume_category = 'HighVolume'
  AND EXISTS (
    SELECT 1
    FROM catalog_returns cr_check
    JOIN date_dim d_check
      ON cr_check.cr_returned_date_sk = d_check.d_date_sk
    WHERE d_check.d_year = 2001
      AND cr_check.cr_return_amount > 500
  )
ORDER BY a.total_net_loss DESC
LIMIT 100
