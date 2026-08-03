WITH
    catalog_agg AS (
        SELECT
            cs.cs_call_center_sk,
            cc.cc_name,
            sm.sm_type,
            SUM(cs.cs_net_paid) AS total_net_paid,
            AVG(cs.cs_sales_price) AS avg_sales_price,
            COUNT(*) AS order_cnt,
            SUM(cr.cr_return_amount) AS total_return_amount,
            ROW_NUMBER() OVER (PARTITION BY cs.cs_call_center_sk ORDER BY SUM(cs.cs_net_paid) DESC) AS rank_cc
        FROM catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN catalog_returns cr
            ON cs.cs_order_number = cr.cr_order_number
            AND cs.cs_item_sk = cr.cr_item_sk
        WHERE cc.cc_state = 'CA'
          AND td.t_hour BETWEEN 9 AND 17
          AND cs.cs_sold_date_sk BETWEEN 2451910 AND 2451919
        GROUP BY cs.cs_call_center_sk, cc.cc_name, sm.sm_type
    ),
    store_agg AS (
        SELECT
            ss.ss_store_sk,
            st.s_store_name,
            SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
            AVG(ss.ss_sales_price) AS avg_sales_price,
            COUNT(*) AS ticket_cnt,
            ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS rank_store
        FROM store_sales ss
        JOIN store st ON ss.ss_store_sk = st.s_store_sk
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN customer cu ON ss.ss_customer_sk = cu.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE st.s_state = 'CA'
          AND td.t_hour BETWEEN 9 AND 17
          AND ss.ss_sold_date_sk BETWEEN 2451910 AND 2451919
        GROUP BY ss.ss_store_sk, st.s_store_name
    ),
    web_agg AS (
        SELECT
            ws.ws_ship_mode_sk,
            sm.sm_type,
            SUM(ws.ws_net_paid_inc_ship) AS total_net_paid,
            AVG(ws.ws_sales_price) AS avg_sales_price,
            COUNT(*) AS order_cnt,
            ROW_NUMBER() OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY SUM(ws.ws_net_paid_inc_ship) DESC) AS rank_ws
        FROM web_sales ws
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN customer cu ON ws.ws_bill_customer_sk = cu.c_customer_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        WHERE sm.sm_type = 'AIR'
          AND td.t_hour BETWEEN 9 AND 17
          AND ws.ws_list_price > 200
        GROUP BY ws.ws_ship_mode_sk, sm.sm_type
    ),
    common_cc AS (
        SELECT cc.cc_call_center_sk FROM call_center cc WHERE cc.cc_state = 'CA'
        INTERSECT
        SELECT cs.cs_call_center_sk FROM catalog_sales cs WHERE cs.cs_sold_date_sk BETWEEN 2451910 AND 2451919
    ),
    union_agg AS (
        SELECT
            ca.cs_call_center_sk AS key_id,
            ca.cc_name AS entity_name,
            ca.sm_type AS ship_mode_type,
            ca.total_net_paid,
            ca.avg_sales_price,
            ca.order_cnt AS txn_cnt,
            ca.rank_cc AS rank
        FROM catalog_agg ca
        UNION
        SELECT
            sa.ss_store_sk AS key_id,
            sa.s_store_name AS entity_name,
            NULL AS ship_mode_type,
            sa.total_net_paid,
            sa.avg_sales_price,
            sa.ticket_cnt AS txn_cnt,
            sa.rank_store AS rank
        FROM store_agg sa
        UNION
        SELECT
            wa.ws_ship_mode_sk AS key_id,
            wa.sm_type AS entity_name,
            wa.sm_type AS ship_mode_type,
            wa.total_net_paid,
            wa.avg_sales_price,
            wa.order_cnt AS txn_cnt,
            wa.rank_ws AS rank
        FROM web_agg wa
    )
SELECT
    ua.key_id,
    ua.entity_name,
    ua.ship_mode_type,
    ua.total_net_paid,
    ua.avg_sales_price,
    ua.txn_cnt,
    ua.rank
FROM union_agg ua
WHERE ua.key_id IN (SELECT cc_call_center_sk FROM common_cc)
ORDER BY ua.total_net_paid DESC
LIMIT 100
