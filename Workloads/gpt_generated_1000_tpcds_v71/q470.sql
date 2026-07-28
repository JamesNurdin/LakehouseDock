WITH agg_ret AS (
    SELECT
        cr_returned_date_sk,
        cr_call_center_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_amount > 50                     -- filter predicate 1
    GROUP BY cr_returned_date_sk, cr_call_center_sk
),
promo_union AS (
    SELECT p_promo_sk,
           p_promo_name,
           p_start_date_sk AS promo_date_sk,
           p_discount_active
    FROM promotion
    WHERE p_discount_active = 'Y'                 -- filter predicate 2 (part 1)
    UNION ALL
    SELECT p_promo_sk,
           p_promo_name,
           p_end_date_sk   AS promo_date_sk,
           p_discount_active
    FROM promotion
    WHERE p_channel_dmail = 'Y'                    -- filter predicate 2 (part 2)
),
web_big AS (
    SELECT wp_web_page_sk,
           wp_url,
           wp_creation_date_sk,
           wp_link_count
    FROM web_page
    WHERE wp_link_count > 15                       -- filter predicate 3
)
SELECT
    d_ret.d_fy_year,
    cc.cc_name,
    cc.cc_employees,
    agg.total_return_amount,
    agg.total_net_loss,
    promo.p_promo_name,
    web.wp_url,
    RANK() OVER (PARTITION BY d_ret.d_fy_year ORDER BY agg.total_net_loss DESC) AS net_loss_rank,
    CASE WHEN promo.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status
FROM agg_ret agg
JOIN call_center cc
  ON agg.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_ret
  ON agg.cr_returned_date_sk = d_ret.d_date_sk
JOIN promo_union promo
  ON promo.promo_date_sk = d_ret.d_date_sk
JOIN web_big web
  ON web.wp_creation_date_sk = d_ret.d_date_sk
WHERE d_ret.d_fy_year BETWEEN 1905 AND 1911               -- additional filter predicate
  AND cc.cc_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr_check
        WHERE cr_check.cr_call_center_sk = cc.cc_call_center_sk
          AND cr_check.cr_return_quantity > 10
    )
GROUP BY
    d_ret.d_fy_year,
    cc.cc_name,
    cc.cc_employees,
    agg.total_return_amount,
    agg.total_net_loss,
    promo.p_promo_name,
    web.wp_url,
    promo.p_discount_active
HAVING SUM(agg.total_return_amount) > 1000
ORDER BY d_ret.d_fy_year DESC, net_loss_rank
LIMIT 100
