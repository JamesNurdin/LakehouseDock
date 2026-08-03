WITH filtered_returns AS (
    SELECT sr.*
    FROM store_returns sr
    WHERE sr.sr_fee > 20
      AND sr.sr_return_quantity >= 1
      AND sr.sr_return_amt > 0
      AND sr.sr_returned_date_sk IS NOT NULL
      AND sr.sr_hdemo_sk IS NOT NULL
      AND sr.sr_item_sk IN (
          SELECT DISTINCT sr2.sr_item_sk
          FROM store_returns sr2
          WHERE sr2.sr_return_quantity > 5
      )
),
joined AS (
    SELECT
        fr.sr_store_sk,
        fr.sr_returned_date_sk,
        fr.sr_return_amt,
        fr.sr_fee,
        fr.sr_return_quantity,
        fr.sr_hdemo_sk,
        fr.sr_reason_sk,
        d.d_year,
        d.d_date,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        r.r_reason_desc,
        p.p_promo_name,
        p.p_discount_active,
        p.p_cost
    FROM filtered_returns fr
    JOIN date_dim d ON fr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON fr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON fr.sr_reason_sk = r.r_reason_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND hd.hd_income_band_sk BETWEEN 3 AND 5
      AND r.r_reason_desc LIKE '%model%'
      AND p.p_discount_active = 'Y'
      AND p.p_cost < 500
),
store_totals AS (
    SELECT
        j.*, 
        SUM(j.sr_return_amt) OVER (PARTITION BY j.sr_store_sk) AS total_store_return,
        SUM(j.sr_return_amt) OVER (PARTITION BY j.sr_store_sk ORDER BY j.d_date ROWS UNBOUNDED PRECEDING) AS cumulative_store_return
    FROM joined j
)
SELECT DISTINCT
    st.d_year,
    st.hd_buy_potential,
    st.r_reason_desc,
    st.p_promo_name,
    st.sr_return_amt,
    st.sr_fee,
    CASE
        WHEN st.sr_return_amt > (SELECT AVG(sr_return_amt) FROM store_returns) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS amt_category,
    st.cumulative_store_return,
    RANK() OVER (PARTITION BY st.d_year ORDER BY st.total_store_return DESC) AS store_year_rank
FROM store_totals st
ORDER BY st.d_year DESC, st.cumulative_store_return DESC
LIMIT 100
