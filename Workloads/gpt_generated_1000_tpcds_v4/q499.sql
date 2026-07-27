WITH
    sub1 AS (
        SELECT
            d.d_year,
            cc.cc_call_center_id            AS entity_id,
            sm.sm_type                      AS transport_type,
            r_cat.r_reason_desc             AS reason_desc,
            cr.cr_return_amount             AS amount,
            cr.cr_net_loss                  AS net_loss,
            CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS loss_indicator,
            ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY d.d_date DESC) AS rn,
            (
                SELECT AVG(cr2.cr_net_loss)
                FROM catalog_returns cr2
                WHERE cr2.cr_returned_date_sk = d.d_date_sk
            ) AS avg_net_loss
        FROM tpcds.date_dim d
        JOIN tpcds.catalog_returns cr
            ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN tpcds.call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN tpcds.ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN tpcds.reason r_cat
            ON cr.cr_reason_sk = r_cat.r_reason_sk
        JOIN tpcds.time_dim td
            ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN tpcds.customer c
            ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN tpcds.customer_address ca
            ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN tpcds.household_demographics hd
            ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN tpcds.inventory inv
            ON inv.inv_date_sk = d.d_date_sk
        JOIN tpcds.web_site ws
            ON ws.web_open_date_sk = d.d_date_sk
        LEFT JOIN tpcds.web_returns wr
            ON wr.wr_returned_date_sk = d.d_date_sk
               AND wr.wr_returned_time_sk = td.t_time_sk
        LEFT JOIN tpcds.reason r_wr
            ON wr.wr_reason_sk = r_wr.r_reason_sk
        WHERE d.d_date >= DATE '2001-01-01'
          AND d.d_date < DATE '2002-01-01'
          AND cc.cc_state = 'CA'
          AND sm.sm_type = 'EXPRESS'
          AND r_cat.r_reason_id = 'AAAAAAAACAAAAAAA'
          AND ws.web_country = 'United States'
    ),
    sub2 AS (
        SELECT
            d.d_year,
            s.s_store_id               AS entity_id,
            NULL                       AS transport_type,
            r_st.r_reason_desc         AS reason_desc,
            sr.sr_return_amt           AS amount,
            sr.sr_net_loss             AS net_loss,
            CASE WHEN sr.sr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS loss_indicator,
            ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY d.d_date DESC) AS rn,
            (
                SELECT AVG(sr2.sr_net_loss)
                FROM store_returns sr2
                WHERE sr2.sr_returned_date_sk = d.d_date_sk
            ) AS avg_net_loss
        FROM tpcds.date_dim d
        JOIN tpcds.store_returns sr
            ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN tpcds.store s
            ON sr.sr_store_sk = s.s_store_sk
        JOIN tpcds.reason r_st
            ON sr.sr_reason_sk = r_st.r_reason_sk
        JOIN tpcds.time_dim td
            ON sr.sr_return_time_sk = td.t_time_sk
        JOIN tpcds.customer_address ca
            ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN tpcds.household_demographics hd
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN tpcds.inventory inv
            ON inv.inv_date_sk = d.d_date_sk
        JOIN tpcds.web_site ws
            ON ws.web_open_date_sk = d.d_date_sk
        WHERE d.d_date >= DATE '2001-01-01'
          AND d.d_date < DATE '2002-01-01'
          AND s.s_state = 'TX'
          AND r_st.r_reason_desc LIKE '%product%'
          AND hd.hd_vehicle_count > 1
          AND ws.web_county = 'Mobile County'
    )
SELECT
    d_year,
    entity_id,
    transport_type,
    reason_desc,
    amount,
    net_loss,
    loss_indicator,
    rn,
    avg_net_loss
FROM (
    SELECT * FROM sub1
    UNION ALL
    SELECT * FROM sub2
) u
ORDER BY d_year DESC, net_loss DESC
LIMIT 100
