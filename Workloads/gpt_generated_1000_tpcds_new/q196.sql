WITH
    promo_agg AS (
        SELECT
            p.p_promo_id   AS key_id,
            p.p_promo_name AS key_desc,
            SUM(ws.ws_ext_sales_price)                                                       AS total_amount,
            SUM(CASE WHEN cd.cd_gender = 'M' THEN ws.ws_ext_sales_price ELSE 0 END)          AS male_amount,
            CASE
                WHEN SUM(CASE WHEN cd.cd_gender = 'M' THEN ws.ws_ext_sales_price ELSE 0 END) > SUM(ws.ws_ext_sales_price) / 2
                THEN 'MALE_DOMINANT'
                ELSE 'OTHER'
            END                                                                           AS category_flag
        FROM web_sales ws
        JOIN promotion p               ON ws.ws_promo_sk   = p.p_promo_sk
        JOIN customer c                ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd  ON ws.ws_bill_cdemo_sk   = cd.cd_demo_sk
        WHERE p.p_channel_event = 'N'
          AND p.p_start_date_sk BETWEEN 2450600 AND 2450700
        GROUP BY p.p_promo_id, p.p_promo_name
    ),
    promo_set AS (
        SELECT
            pa.key_id,
            pa.key_desc,
            pa.total_amount,
            pa.male_amount,
            pa.category_flag
        FROM promo_agg pa
        CROSS JOIN (
            SELECT r_reason_id FROM reason WHERE r_reason_sk IN (5, 12)
        ) d
    ),
    return_agg AS (
        SELECT
            r.r_reason_id   AS key_id,
            r.r_reason_desc AS key_desc,
            SUM(wr.wr_refunded_cash)                                                       AS total_amount,
            SUM(CASE WHEN cd.cd_gender = 'M' THEN wr.wr_refunded_cash ELSE 0 END)          AS male_amount,
            CASE
                WHEN SUM(CASE WHEN cd.cd_gender = 'M' THEN wr.wr_refunded_cash ELSE 0 END) > SUM(wr.wr_refunded_cash) / 2
                THEN 'MALE_DOMINANT'
                ELSE 'OTHER'
            END                                                                            AS category_flag
        FROM web_returns wr
        JOIN reason r               ON wr.wr_reason_sk = r.r_reason_sk
        JOIN customer c             ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk   = cd.cd_demo_sk
        WHERE wr.wr_returned_date_sk BETWEEN 2450600 AND 2450700
          AND r.r_reason_desc LIKE '%price%'
        GROUP BY r.r_reason_id, r.r_reason_desc
    ),
    return_set AS (
        SELECT
            ra.key_id,
            ra.key_desc,
            ra.total_amount,
            ra.male_amount,
            ra.category_flag
        FROM return_agg ra
        CROSS JOIN (
            SELECT r_reason_id FROM reason WHERE r_reason_sk IN (5, 12)
        ) d
    )
SELECT
    key_id,
    key_desc,
    total_amount,
    male_amount,
    category_flag
FROM promo_set
UNION
SELECT
    key_id,
    key_desc,
    total_amount,
    male_amount,
    category_flag
FROM return_set
ORDER BY total_amount DESC
LIMIT 100
