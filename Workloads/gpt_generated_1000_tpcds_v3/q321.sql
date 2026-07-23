WITH joined_raw AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_store_sk,
        sr.sr_customer_sk,
        sr.sr_addr_sk,
        sr.sr_cdemo_sk,
        sr.sr_reason_sk,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        cd.cd_gender,
        s.s_store_name,
        s.s_state,
        r.r_reason_id,
        r.r_reason_desc,
        ws.ws_ext_sales_price,
        ws.ws_promo_sk,
        p.p_discount_active,
        p.p_channel_email,
        w.w_warehouse_name
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE sr.sr_return_amt > 100
      AND ws.ws_ext_sales_price > 500
      AND p.p_discount_active = 'Y'
      AND ca.ca_state = 'CA'
      AND s.s_state = 'CA'
      AND r.r_reason_id = '1'
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_promo_sk = ws.ws_promo_sk
            AND p2.p_channel_email = 'Y'
      )
),
store_customer_agg AS (
    SELECT
        sr_store_sk,
        s_store_name,
        c_customer_sk,
        c_customer_id,
        c_first_name,
        c_last_name,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws_promo_sk) AS distinct_promo_cnt
    FROM joined_raw
    GROUP BY sr_store_sk, s_store_name, c_customer_sk, c_customer_id, c_first_name, c_last_name
),
final AS (
    SELECT
        s_store_name,
        c_customer_id,
        c_first_name,
        c_last_name,
        total_return_amt,
        total_web_sales,
        distinct_promo_cnt,
        ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_return_amt DESC) AS store_return_rank,
        (SELECT AVG(total_return_amt) FROM store_customer_agg) AS avg_total_return_amt
    FROM store_customer_agg
)
SELECT DISTINCT
    s_store_name,
    c_customer_id,
    c_first_name,
    c_last_name,
    total_return_amt,
    total_web_sales,
    distinct_promo_cnt,
    store_return_rank,
    avg_total_return_amt
FROM final
WHERE store_return_rank <= 10
ORDER BY total_return_amt DESC, store_return_rank
LIMIT 100
