/*
  Goal: Summarize store return performance by state, city and store, showing subtotals and grand total. The query joins customer, household_demographics, store and store_returns, applies multiple filters, uses a CTE for per‑customer aggregates, a scalar subquery to keep only above‑average return amounts, counts distinct customers, and leverages GROUPING SETS for hierarchical roll‑up.
*/
WITH store_customer_agg AS (
    SELECT
        st.s_store_id               AS store_id,
        st.s_state                  AS state,
        st.s_city                   AS city,
        cu.c_customer_id            AS customer_id,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_return_quantity)    AS total_return_qty,
        COUNT(*)                      AS return_cnt
    FROM store AS st
    JOIN store_returns AS sr
        ON st.s_store_sk = sr.sr_store_sk
    JOIN customer AS cu
        ON sr.sr_customer_sk = cu.c_customer_sk
    JOIN household_demographics AS hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE cu.c_preferred_cust_flag = 'Y'
      AND cu.c_current_hdemo_sk IN (2821, 3446, 725)
      AND st.s_county = 'Gage County'
      AND st.s_company_name = 'Unknown'
      AND sr.sr_store_credit > 100
      AND sr.sr_return_amt_inc_tax BETWEEN 50 AND 500
      AND hd.hd_vehicle_count >= 2
    GROUP BY
        st.s_store_id,
        st.s_state,
        st.s_city,
        cu.c_customer_id
)
SELECT
    agg.state,
    agg.city,
    agg.store_id,
    SUM(agg.total_return_amount)                AS state_city_store_return_amount,
    AVG(agg.total_return_amount)                AS avg_customer_return_amount,
    COUNT(DISTINCT agg.customer_id)             AS distinct_customers,
    GROUPING(agg.state)                         AS grp_state,
    GROUPING(agg.city)                          AS grp_city,
    GROUPING(agg.store_id)                      AS grp_store
FROM store_customer_agg AS agg
WHERE agg.total_return_amount > (
        SELECT AVG(total_return_amount)
        FROM store_customer_agg
    )
GROUP BY GROUPING SETS (
    (agg.state, agg.city, agg.store_id),
    (agg.state, agg.city),
    (agg.state),
    ()
)
ORDER BY
    agg.state,
    agg.city,
    agg.store_id
LIMIT 100
