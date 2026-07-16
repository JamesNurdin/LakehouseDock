SELECT
    st.s_store_id,
    st.s_store_name,
    st.s_city,
    st.s_state,
    ds.d_date AS store_closed_date,
    dr.d_date AS return_date,
    dr.d_year,
    dr.d_month_seq,
    cp.cp_catalog_page_number,
    cp.cp_type,
    cp.cp_description,
    dcp_end.d_date AS catalog_end_date,
    p.p_promo_name,
    p.p_cost,
    dp_end.d_date AS promo_end_date,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_ticket_count,
    AVG(p.p_cost) OVER (PARTITION BY st.s_store_id) AS avg_promo_cost_for_store
FROM
    store_returns sr
    JOIN store st
        ON sr.sr_store_sk = st.s_store_sk
    JOIN date_dim dr
        ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN date_dim ds
        ON st.s_closed_date_sk = ds.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = dr.d_date_sk
    JOIN date_dim dcp_end
        ON cp.cp_end_date_sk = dcp_end.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = dr.d_date_sk
    JOIN date_dim dp_end
        ON p.p_end_date_sk = dp_end.d_date_sk
WHERE
    dr.d_date <= dcp_end.d_date
    AND dr.d_date <= dp_end.d_date
    AND p.p_discount_active = 'Y'
    AND cp.cp_type = 'FEATURED'
GROUP BY
    st.s_store_id,
    st.s_store_name,
    st.s_city,
    st.s_state,
    ds.d_date,
    dr.d_date,
    dr.d_year,
    dr.d_month_seq,
    cp.cp_catalog_page_number,
    cp.cp_type,
    cp.cp_description,
    dcp_end.d_date,
    p.p_promo_name,
    p.p_cost,
    dp_end.d_date
ORDER BY
    total_return_amount DESC
LIMIT 100
