WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_net_loss,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        hd.hd_buy_potential,
        st.s_state,
        st.s_tax_percentage,
        ws.web_mkt_class,
        d_ret.d_year,
        d_close.d_date AS store_closed_date
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN date_dim d_close ON st.s_closed_date_sk = d_close.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND hd.hd_vehicle_count >= 2
      AND st.s_state = 'CA'
      AND ws.web_mkt_class LIKE '%new%'
      AND st.s_tax_percentage > (
          SELECT MAX(s_tax_percentage)
          FROM store
          WHERE s_state = 'TX'
      )
),
union_data AS (
    SELECT
        fr.sr_store_sk,
        fr.s_state,
        fr.sr_return_amt,
        fr.sr_return_tax,
        fr.hd_dep_count,
        CASE WHEN fr.hd_dep_count > 3 THEN 'HIGH_DEP' ELSE 'LOW_DEP' END AS dep_category
    FROM filtered_returns fr
    WHERE fr.hd_dep_count > 3
    UNION DISTINCT
    SELECT
        fr.sr_store_sk,
        fr.s_state,
        fr.sr_return_amt,
        fr.sr_return_tax,
        fr.hd_dep_count,
        CASE WHEN fr.hd_dep_count > 3 THEN 'HIGH_DEP' ELSE 'LOW_DEP' END AS dep_category
    FROM filtered_returns fr
    WHERE fr.hd_dep_count <= 3
)
SELECT
    ud.sr_store_sk,
    ud.s_state,
    ud.dep_category,
    SUM(ud.sr_return_amt) AS total_return_amount,
    AVG(ud.sr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_rows,
    CASE WHEN SUM(ud.sr_return_amt) > 15000 THEN 'VERY_HIGH' ELSE 'NORMAL' END AS amount_category
FROM union_data ud
GROUP BY
    ud.sr_store_sk,
    ud.s_state,
    ud.dep_category
ORDER BY total_return_amount DESC
LIMIT 100
