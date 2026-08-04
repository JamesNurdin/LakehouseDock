WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),
sales_with_dims AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_net_paid,
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        cd.cd_education_status,
        p.p_promo_name,
        p.p_discount_active
    FROM sampled_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
),
promo_dates AS (
    SELECT
        p.p_promo_sk,
        d_start.d_year AS start_year,
        d_end.d_year AS end_year
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
),
full_ship_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        sm.sm_type,
        sm.sm_carrier
    FROM catalog_returns cr
    FULL OUTER JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
),
ship_mode_alias AS (
    SELECT
        cr.cr_returned_date_sk,
        sm2.sm_type AS sm_type_2,
        sm2.sm_carrier AS sm_carrier_2
    FROM catalog_returns cr
    LEFT JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
),
web_dates AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        d_open.d_year AS open_year,
        d_close.d_year AS close_year,
        ws.web_gmt_offset
    FROM web_site ws
    JOIN date_dim d_open ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
),
store_returns_joined AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        ss.ss_sold_date_sk,
        ss.ss_net_paid
    FROM store_returns sr
    JOIN sampled_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
),
returns_ticket AS (
    SELECT sr.sr_ticket_number AS ticket
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
),
refunds_ticket AS (
    SELECT cr.cr_order_number AS ticket
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
),
common_tickets AS (
    SELECT ticket FROM returns_ticket
    INTERSECT
    SELECT ticket FROM refunds_ticket
),
sales_with_avg AS (
    SELECT
        swd.*,
        la.avg_net_paid
    FROM sales_with_dims swd
    CROSS JOIN LATERAL (
        SELECT AVG(ss2.ss_net_paid) AS avg_net_paid
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = swd.ss_item_sk
    ) la
),
union_set AS (
    SELECT
        swa.ss_ticket_number AS key_id,
        swa.ss_net_paid AS metric,
        swa.d_year AS year,
        swa.cd_gender AS gender,
        swa.p_promo_name AS promo_name,
        swa.avg_net_paid AS avg_metric
    FROM sales_with_avg swa
    WHERE swa.d_year = 2001

    UNION DISTINCT

    SELECT
        fr.cr_returned_date_sk AS key_id,
        fr.cr_return_amount AS metric,
        pd.start_year AS year,
        NULL AS gender,
        NULL AS promo_name,
        NULL AS avg_metric
    FROM full_ship_returns fr
    JOIN promo_dates pd ON 1 = 1
    WHERE fr.cr_return_amount > 100
)
SELECT
    us.key_id,
    COUNT(*) AS cnt,
    SUM(us.metric) AS total_metric,
    AVG(us.avg_metric) FILTER (WHERE us.avg_metric IS NOT NULL) AS avg_of_avg_metric,
    MIN(us.year) AS min_year,
    MAX(us.year) AS max_year
FROM union_set us
WHERE us.key_id IS NOT NULL
  AND EXISTS (SELECT 1 FROM common_tickets ct WHERE ct.ticket = us.key_id)
GROUP BY us.key_id, us.year, us.gender, us.promo_name
ORDER BY total_metric DESC
LIMIT 100
