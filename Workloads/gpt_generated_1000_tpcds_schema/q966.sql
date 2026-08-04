WITH sales_promo AS (
    SELECT
        ws.ws_sold_date_sk,
        d.d_year,
        p.p_promo_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_response_target = 1
    GROUP BY GROUPING SETS (
        (ws.ws_sold_date_sk, d.d_year, p.p_promo_id),
        (d.d_year, p.p_promo_id)
    )
),
store_ret AS (
    SELECT sr.sr_returned_date_sk,
           SUM(sr.sr_return_amt) AS sr_return_amount_sum
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk
),
web_ret AS (
    SELECT wr.wr_returned_date_sk,
           SUM(wr.wr_return_amt) AS wr_return_amount_sum
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
),
full_returns AS (
    SELECT
        COALESCE(st.sr_returned_date_sk, wr.wr_returned_date_sk) AS return_date_sk,
        d.d_year,
        st.sr_return_amount_sum,
        wr.wr_return_amount_sum
    FROM store_ret st
    FULL OUTER JOIN web_ret wr
        ON st.sr_returned_date_sk = wr.wr_returned_date_sk
    JOIN date_dim d
        ON d.d_date_sk = COALESCE(st.sr_returned_date_sk, wr.wr_returned_date_sk)
)
SELECT
    combined.d_year,
    combined.promo_id,
    combined.total_sales,
    combined.order_cnt,
    combined.sr_return_amount_sum,
    combined.wr_return_amount_sum,
    (
        SELECT MAX(p_cost)
        FROM promotion p
        WHERE p.p_promo_id = combined.promo_id
    ) AS max_promo_cost
FROM (
    SELECT
        sp.d_year,
        sp.p_promo_id AS promo_id,
        sp.total_sales,
        sp.order_cnt,
        NULL AS sr_return_amount_sum,
        NULL AS wr_return_amount_sum
    FROM sales_promo sp
    WHERE sp.total_sales > 1000

    UNION ALL

    SELECT
        fr.d_year,
        NULL AS promo_id,
        NULL AS total_sales,
        NULL AS order_cnt,
        fr.sr_return_amount_sum,
        fr.wr_return_amount_sum
    FROM full_returns fr
    WHERE fr.sr_return_amount_sum > 500 OR fr.wr_return_amount_sum > 500
) combined
WHERE EXISTS (
    SELECT 1
    FROM promotion p
    WHERE p.p_promo_id = combined.promo_id
      AND p.p_channel_radio = 'N'
)
  AND combined.d_year IN (
      SELECT d_year FROM (SELECT d_year FROM sales_promo) INTERSECT SELECT d_year FROM full_returns
  )
ORDER BY combined.d_year DESC, combined.total_sales DESC NULLS LAST
OFFSET 0 LIMIT 100
