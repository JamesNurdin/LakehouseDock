SELECT
    d.d_year,
    st.s_state,
    i.i_category,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_net_paid ELSE 0 END) AS promo_net_paid
FROM
    store_sales ss
JOIN
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN
    store st ON ss.ss_store_sk = st.s_store_sk
JOIN
    item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN
    promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE
    d.d_year BETWEEN 1999 AND 2002
GROUP BY
    d.d_year,
    st.s_state,
    i.i_category
ORDER BY
    d.d_year,
    st.s_state,
    i.i_category
