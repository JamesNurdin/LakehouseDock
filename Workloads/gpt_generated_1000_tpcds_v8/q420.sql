WITH
  store_ret_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      s.s_store_name,
      SUM(sr.sr_net_loss) AS total_store_net_loss,
      COUNT(*) AS store_return_cnt,
      CASE WHEN SUM(sr.sr_return_quantity) > 10 THEN 'HIGH' ELSE 'LOW' END AS return_volume_category
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_state = 'CA'
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2451000
      AND ca.ca_city = 'Chicago'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, s.s_store_name
  ),
  web_ret_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ws.ws_web_site_sk,
      SUM(wr.wr_net_loss) AS total_web_net_loss,
      COUNT(*) AS web_return_cnt,
      CASE WHEN SUM(wr.wr_return_quantity) > 5 THEN 'HIGH' ELSE 'LOW' END AS return_volume_category
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wsite.web_state = 'CA'
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2451000
      AND wsite.web_company_name = 'cally'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ws.ws_web_site_sk
  ),
  union_agg AS (
    SELECT
      c_customer_sk,
      c_first_name,
      c_last_name,
      CAST(NULL AS varchar) AS store_name,
      total_web_net_loss AS total_net_loss,
      web_return_cnt AS return_cnt,
      return_volume_category
    FROM web_ret_agg
    UNION DISTINCT
    SELECT
      c_customer_sk,
      c_first_name,
      c_last_name,
      s_store_name AS store_name,
      total_store_net_loss AS total_net_loss,
      store_return_cnt AS return_cnt,
      return_volume_category
    FROM store_ret_agg
  ),
  key_set_store AS (
    SELECT sr.sr_ticket_number AS ticket
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2451000
  ),
  key_set_web AS (
    SELECT wr.wr_order_number AS ticket
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2451000
  ),
  tickets_exclusive AS (
    SELECT ticket FROM key_set_store
    EXCEPT
    SELECT ticket FROM key_set_web
  ),
  tickets_common AS (
    SELECT ticket FROM key_set_store
    INTERSECT
    SELECT ticket FROM key_set_web
  )
SELECT
  ua.c_customer_sk,
  ua.c_first_name,
  ua.c_last_name,
  ua.store_name,
  ua.total_net_loss,
  ua.return_cnt,
  ua.return_volume_category,
  (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_customer_sk = ua.c_customer_sk) AS total_store_returns_for_customer,
  (SELECT COUNT(*) FROM tickets_exclusive) AS exclusive_ticket_count,
  (SELECT COUNT(*) FROM tickets_common) AS common_ticket_count
FROM union_agg ua
ORDER BY ua.total_net_loss DESC
LIMIT 100
